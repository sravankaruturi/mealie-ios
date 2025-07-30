import SwiftUI
import SwiftData

struct RecipeListView: View {
    
    var mealieAPIService: MealieAPIServiceProtocol
    
    @State var recipesViewModel: RecipesViewModel
    @State private var searchText: String = ""
    @State private var showAddRecipeOptions = false
    @State private var showURLImportSheet = false
    @State private var selectedRecipe: Recipe? // Recipe to navigate to after import
    
    @Environment(\.modelContext) private var modelContext
    
    let gridItemWidth: CGFloat = 180
    let gridItemHeight: CGFloat = 140
    
    var filteredRecipes: [Recipe] {
        if searchText.isEmpty { return recipesViewModel.recipes }
        return recipesViewModel.recipes.filter { $0.name!.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                ScrollView{
                    Grid (horizontalSpacing: 10, verticalSpacing: 10){
                        ForEach(Array(stride(from: 0, to: filteredRecipes.count, by: 2)), id: \.self) { index in
                            GridRow{
                                NavigationLink(destination: RecipeDetailView(recipe: filteredRecipes[index], mealieAPIService: self.mealieAPIService)) {
                                    RecipeCardView(recipe: filteredRecipes[index], mealieAPIService: mealieAPIService)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .frame(width: gridItemWidth, height: gridItemHeight)
                                
                                if index + 1 < filteredRecipes.count {
                                    NavigationLink(destination: RecipeDetailView(recipe: filteredRecipes[index + 1], mealieAPIService: self.mealieAPIService)) {
                                        RecipeCardView(recipe: filteredRecipes[index + 1], mealieAPIService: mealieAPIService)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .frame(width: gridItemWidth, height: gridItemHeight)
                                }
                            }
                        }
                    }
                    .navigationTitle("Recipes")
                    .searchable(text: $searchText, prompt: "Search Recipes")
                    .listStyle(PlainListStyle())
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                Task {
                                    await recipesViewModel.forceSyncRecipes()
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                    }
                }
                
                if showAddRecipeOptions {
                    LinearGradient(stops: [.init(color: .white.opacity(1.0), location: 0), .init(color: .white.opacity(0.5), location: 1)], startPoint: .bottomTrailing, endPoint: .topLeading)
                        .ignoresSafeArea(.all)
                        .onTapGesture {
                            withAnimation(.easeOut) {
                                showAddRecipeOptions.toggle()
                            }
                        }
                }
                
                // Floating Action Button
                VStack( alignment: .trailing) {
                    Spacer()
                    
                    if showAddRecipeOptions {
                        AddRecipeOptionsView(
                            onURLImport: {
                                withAnimation(.interpolatingSpring) {
                                    showAddRecipeOptions.toggle()
                                    showURLImportSheet.toggle()
                                }
                            }, onManualImport: {
                                
                            }
                        )
                        .padding(.bottom, 10)
                    }
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation(.interpolatingSpring) {
                                showAddRecipeOptions.toggle()
                            }
                        }) {
                            Image(systemName: showAddRecipeOptions ? "xmark" : "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.orange)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationDestination(item: $selectedRecipe) { recipe in
                RecipeDetailView(recipe: recipe, mealieAPIService: self.mealieAPIService)
            }
        }
        .sheet(isPresented: $showURLImportSheet) {
            ImportRecipeFromURLView(
                mealieAPIService: self.mealieAPIService,
                onRecipeImported: { recipeSlug in
                    // Handle successful recipe import
                    showURLImportSheet = false
                    navigateToRecipeBySlug(recipeSlug)
                }, recipesViewModel: recipesViewModel
            )
            .presentationDetents([.medium, .fraction(0.3)])
        }
    }
    
    private func navigateToRecipeBySlug(_ recipeSlug: String) {
        // Find the recipe in the current list (it should be there after import)
        if let recipe = recipesViewModel.recipes.first(where: { $0.slug == recipeSlug }) {
            selectedRecipe = recipe
        } else {
            // Fallback: Recipe not found in current list, try to fetch it
            Task {
                do {
                    let apiService = self.mealieAPIService
                    let fetchedRecipe = try await apiService.fetchRecipeDetails(slug: recipeSlug)
                    
                    await MainActor.run {
                        // Add to local storage and navigate
                        modelContext.insert(fetchedRecipe)
                        try? modelContext.save()
                        recipesViewModel.recipes.append(fetchedRecipe)
                        selectedRecipe = fetchedRecipe
                    }
                } catch {
                    print("Error fetching recipe: \(error)")
                }
            }
        }
    }
}

#Preview {
    
    let mockService = MockMealieAPIService()
    
    let modelContainer = try! ModelContainer(for: Recipe.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    
    // Insert sample recipe into the model context
    modelContainer.mainContext.insert(MockMealieAPIService.sampleRecipe)
    modelContainer.mainContext.insert(MockMealieAPIService.favoriteRecipe)
    modelContainer.mainContext.insert(MockMealieAPIService.thirdRecipe)
    modelContainer.mainContext.insert(MockMealieAPIService.fourthRecipe)
    modelContainer.mainContext.insert(MockMealieAPIService.fifthRecipe)
    modelContainer.mainContext.insert(MockMealieAPIService.sixthRecipe)
    modelContainer.mainContext.insert(MockMealieAPIService.seventhRecipe)
    modelContainer.mainContext.insert(MockMealieAPIService.eightRecipe)
    
    // Create the view model with the model context
    let recipesViewModel = RecipesViewModel(modelContext: modelContainer.mainContext, mealieAPIService: mockService)
    
    return RecipeListView(mealieAPIService: mockService, recipesViewModel: recipesViewModel)
        .modelContainer(modelContainer)
}
