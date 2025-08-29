import SwiftUI
import SwiftData

struct EditRecipeBodyView : View {
    
    @Environment(\.dismiss) var dismiss
    
    let modelContext: ModelContext
    let user: User
    let isNewRecipe: Bool
    
    @State internal var viewModel: EditRecipeViewModel
    @State internal var nutrition: String = ""
    
    init(recipe: Recipe, modelContext: ModelContext, mealieAPIService: MealieAPIServiceProtocol, user: User, isNewRecipe: Bool) {
        self.modelContext = modelContext
        self.user = user
        self.viewModel = EditRecipeViewModel(modelContext: modelContext, recipe: recipe, mealieAPIService: mealieAPIService, user: user)
        self.isNewRecipe = isNewRecipe
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    nameSection
                    photosSection
                    websiteSection
                    ingredientsSection
                    instructionsSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Update") {
                        Task {
                            await viewModel.saveRecipe(isNew: isNewRecipe)
                            if viewModel.showSuccess {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.name.isEmpty)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Saving...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(10)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
            .sheet(isPresented: $viewModel.isPresentingSheet) {
                if let ingredient = viewModel.selectedIngredient {
                    IngredientInputView(
                        quantity: String(ingredient.quantity),
                        selectedUnit: ingredient.unit.name,
                        itemName: ingredient.name,
                        originalIngredient: ingredient, availableUnits: viewModel.availableUnits
                    ) { updatedIngredient in
                        viewModel.saveIngredient(updatedIngredient)
                    }
                }
            }
        }
    }
    
    private var nameSection: some View {
        VStack{
            TextField("Name", text: $viewModel.name)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .onChange(of: viewModel.name) {
                    viewModel.updateSlugBasedOnName()
                }
            
            HStack{
                Text("Slug: \(viewModel.slug)")
                    .font(.caption)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
    }
    
    private var nutritionSection: some View {
        TextField("Add Nutritional Information", text: $nutrition)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .disabled(true)
    }
    
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PHOTOS")
                .font(.caption)
                .foregroundColor(.secondary)
//            if let image = viewModel.photoImage {
//                Image(uiImage: image)
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(height: 120)
//                    .cornerRadius(10)
//            }
//            Button(action: viewModel.addPhoto) {
//                HStack {
//                    Image(systemName: "plus.circle.fill")
//                    Text("Add Photo")
//                }
//                .frame(maxWidth: .infinity)
//                .padding()
//                .background(Color(.systemBlue).opacity(0.15))
//                .cornerRadius(16)
//            }
        }
        .padding(.horizontal)
    }
    
    private var websiteSection: some View {
        VStack(spacing: 0) {
            EmptyView()
            HStack {
                Text("Website")
                Spacer()
                TextField("Website URL", text: $viewModel.orgURL)
            }
            .padding()
            Divider()
        }
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TAGS")
                .font(.caption)
                .foregroundColor(.secondary)
//            Button(action: viewModel.addTags) {
//                HStack {
//                    Image(systemName: "plus.circle.fill")
//                    Text("Add Tags")
//                }
//                .frame(maxWidth: .infinity)
//                .padding()
//                .background(Color(.systemBlue).opacity(0.15))
//                .cornerRadius(16)
//            }
        }
        .padding(.horizontal)
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("INGREDIENTS")
                .font(.caption)
                .foregroundColor(.secondary)
            ForEach(Array(viewModel.ingredients.enumerated()), id: \.element.id) { index, ingredient in
                self.ingredientRow(index: index, ingredient: ingredient)
            }
            Button(action: viewModel.addIngredient) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Ingredient")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBlue).opacity(0.15))
                .cornerRadius(16)
            }
        }
        .padding(.horizontal)
    }
    
    // ingredientRow function moved to EditRecipeRowViews.swift
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("INSTRUCTIONS")
                .font(.caption)
                .foregroundColor(.secondary)
            let grouped = Dictionary(grouping: viewModel.instructions) { $0.title ?? "" }
            ForEach(Array(grouped.keys.sorted()), id: \.self) { section in
                if !section.isEmpty {
                    Text(section)
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.vertical, 4)
                }
                ForEach((grouped[section] ?? []).sorted(by: { $0.step < $1.step }), id: \.id) { instruction in
                    self.instructionRow(instruction: instruction)
            }
            }
            Button(action: viewModel.addInstructionSection) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Section")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBlue).opacity(0.15))
                .cornerRadius(16)
            }
            Button(action: viewModel.addInstruction) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Step")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBlue).opacity(0.15))
                .cornerRadius(16)
            }
        }
        .padding(.horizontal)
    }

    // instructionRow function moved to EditRecipeRowViews.swift
}

struct EditRecipeView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Environment(AuthenticationState.self) var authState
    
    var mealieAPIService: MealieAPIServiceProtocol
    
    let recipe: Recipe
    let isNewRecipe: Bool
    
    var body: some View {
        Group {
            if let user = authState.user {
                EditRecipeBodyView(recipe: recipe, modelContext: modelContext, mealieAPIService: self.mealieAPIService, user: user, isNewRecipe: isNewRecipe
                )
            } else {
                Text("Loading... user is not logged in")
            }
        }
    }
    
}

#Preview {
    
    let sampleRecipe = Recipe.sampleData
    let mockAPI = MockMealieAPIService()
    
    var authState = AuthenticationState(authService: MockAuthenticationService())
    Task {
        let url: URL = URL(string: "https://test.com")!
        try! await authState.login(username: "test", password: "test", serverURL: url)
    }
    
    return EditRecipeView(mealieAPIService: mockAPI, recipe: sampleRecipe, isNewRecipe: false)
        .environment(authState)
}
