import SwiftUI
import SwiftData

struct RecipeListView: View {
    
    var mealieAPIService: MealieAPIServiceProtocol
    
    @State var recipesViewModel: RecipesViewModel
    @State private var searchText: String = ""
    @State private var showAddRecipeSheet = false
    @State private var showURLImportSheet = false
    @State private var selectedRecipe: Recipe? // Recipe to navigate to after import
    @Environment(\.modelContext) private var modelContext
    
    var filteredRecipes: [Recipe] {
        if searchText.isEmpty { return recipesViewModel.recipes }
        return recipesViewModel.recipes.filter { $0.name!.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                List(filteredRecipes) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe, mealieAPIService: self.mealieAPIService)) {
                        RecipeCardView(recipe: recipe, mealieAPIService: mealieAPIService)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .listStyle(.plain)
                .navigationTitle("Recipes")
                .searchable(text: $searchText, prompt: "Search Recipes")
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
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showAddRecipeSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.blue)
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
        .sheet(isPresented: $showAddRecipeSheet) {
            AddRecipeSheetView(onURLImport: {
                showAddRecipeSheet = false
                showURLImportSheet = true
            })
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

// Sheet view for adding recipes
struct AddRecipeSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    let onURLImport: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                Button(action: { 
                    // TODO: Implement manual recipe form
                    dismiss()
                }) {
                    Text("Manual")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: { 
                    onURLImport()
                }) {
                    Text("From URL")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .padding()
            .navigationTitle("Add Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
