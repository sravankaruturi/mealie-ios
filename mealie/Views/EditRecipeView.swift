import SwiftUI
import SwiftData

struct EditRecipeBodyView : View {
    
    @Environment(\.dismiss) var dismiss
    
    let modelContext: ModelContext
    let user: User
    let isNewRecipe: Bool
    
    @State private var viewModel: EditRecipeViewModel
    @State private var nutrition: String = ""
    @State private var editingIngredientIndex: Int? = nil
    
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
//                    nutritionSection
                    photosSection
                    websiteSection
//                    tagsSection
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
            .sheet(isPresented: Binding<Bool>(
                get: { editingIngredientIndex != nil },
                set: { if !$0 { editingIngredientIndex = nil } }
            )) {
                if let index = editingIngredientIndex {
                    IngredientEditSheet(
                        ingredient: $viewModel.ingredients[index],
                        onSave: { updated in viewModel.ingredients[index] = updated; editingIngredientIndex = nil },
                        onCancel: { editingIngredientIndex = nil }
                    )
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
                ingredientRow(index: index, ingredient: ingredient)
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
    
    @ViewBuilder
    private func ingredientRow(index: Int, ingredient: Ingredient) -> some View {
        HStack {
            Button(action: { viewModel.removeIngredient(at: IndexSet(integer: index)) }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
            Button(action: { editingIngredientIndex = index }) {
                HStack(spacing: 4) {
                    Text(String(ingredient.quantity))
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                    Text(ingredient.unit.name)
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                    Text(ingredient.name)
                        .foregroundColor(.primary)
                }
            }
            Spacer()
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .background(Color(.systemBackground))
    }
    
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
                    instructionRow(instruction: instruction)
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

    @ViewBuilder
    private func instructionRow(instruction: Instruction) -> some View {
        HStack(alignment: .top) {
            Button(action: { viewModel.removeInstruction(id: instruction.id) }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
            Text("\(instruction.step).")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)
            TextField("Instruction step", text: Binding(
                get: { instruction.text },
                set: { newValue in
                    if let idx = viewModel.instructions.firstIndex(where: { $0.id == instruction.id }) {
                        viewModel.instructions[idx].text = newValue
                    }
                }
            ), axis: .vertical)
            .textFieldStyle(.roundedBorder)
            .lineLimit(2...6)
            Spacer()
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .background(Color(.systemBackground))
    }
}

struct EditRecipeView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Environment(AuthenticationState.self) var authState
    
    var mealieAPIService: MealieAPIServiceProtocol
    
    let recipe: Recipe
    let isNewRecipe: Bool
    
    var body: some View {
        EditRecipeBodyView(recipe: recipe, modelContext: modelContext, mealieAPIService: self.mealieAPIService, user: authState.user!, isNewRecipe: isNewRecipe)
    }
    
}
    
    

// Placeholder for ingredient editing sheet
struct IngredientEditSheet: View {
    
    @Binding var ingredient: Ingredient
    var onSave: (Ingredient) -> Void
    var onCancel: () -> Void
    
    @State private var quantity: String = ""
    @State private var unit: IngredientUnit = IngredientUnit(name: "")
    @State private var name: String = ""
    @State private var editingField: EditingField = .quantity
    
    enum EditingField { case quantity, unit, name }
    
    let units: [IngredientUnit] = [
        IngredientUnit(name: "Item"),
        IngredientUnit(name: "Tablespoon"),
        IngredientUnit(name: "Teaspoon"),
        IngredientUnit(name: "Cup"),
        IngredientUnit(name: "ml"),
        IngredientUnit(name: "g"),
        IngredientUnit(name: "kg"),
        IngredientUnit(name: "oz"),
        IngredientUnit(name: "lb"),
        IngredientUnit(name: "bunch")
    ]
    let fractions = ["¼", "⅓", "½", "⅔", "¾"]
    let numbers = ["1","2","3","4","5","6","7","8","9","0"]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button("Save") {
                    saveAndClose()
                }
                .font(.headline)
                .foregroundColor(.blue)
                Spacer()
                Button("Next") {
                    goToNextField()
                }
                .font(.headline)
                .foregroundColor(.green)
            }
            .padding(.horizontal)
            
            Spacer(minLength: 0)
            
            // Large preview
            VStack(spacing: 4) {
                Text("\(quantity) \(unit.name) \(name)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.top, 8)
                Text("Edit \(editingField == .quantity ? "Quantity" : editingField == .unit ? "Unit" : "Name")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
            
            // Custom number pad/unit picker
            if editingField == .quantity {
                HStack(spacing: 8) {
                    ForEach(fractions, id: \.self) { frac in
                        Button(frac) { quantity.append(frac) }
                            .ingredientPadButton()
                    }
                }
                .padding(.bottom, 2)
                HStack(spacing: 8) {
                    ForEach(["1","2","3"], id: \.self) { n in
                        Button(n) { quantity.append(n) }
                            .ingredientPadButton()
                    }
                }
                HStack(spacing: 8) {
                    ForEach(["4","5","6"], id: \.self) { n in
                        Button(n) { quantity.append(n) }
                            .ingredientPadButton()
                    }
                }
                HStack(spacing: 8) {
                    ForEach(["7","8","9"], id: \.self) { n in
                        Button(n) { quantity.append(n) }
                            .ingredientPadButton()
                    }
                }
                HStack(spacing: 8) {
                    Button("0") { quantity.append("0") }
                        .ingredientPadButton()
                    Button(".") { quantity.append(".") }
                        .ingredientPadButton()
                    Button("delete") { if !quantity.isEmpty { quantity.removeLast() } }
                        .ingredientPadButton(background: .red.opacity(0.15), foreground: .red)
                }
            } else if editingField == .unit {
                Picker("Unit", selection: $unit) {
                    ForEach(units) { u in
                        Text(u.name).tag(u)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
            } else if editingField == .name {
                TextField("Ingredient name", text: $name)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .font(.title2)
                    .padding(.horizontal)
            }
            
            Spacer(minLength: 0)
            
            HStack {
                ForEach([EditingField.quantity, .unit, .name], id: \.self) { field in
                    Button(action: { editingField = field }) {
                        Text(field == .quantity ? "Quantity" : field == .unit ? "Unit" : "Name")
                            .fontWeight(editingField == field ? .bold : .regular)
                            .foregroundColor(editingField == field ? .blue : .primary)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(editingField == field ? Color.blue.opacity(0.1) : Color.clear)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            
            Button("Cancel", action: onCancel)
                .foregroundColor(.red)
                .padding(.top, 8)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .onAppear {
            quantity = String(ingredient.quantity)
            unit = ingredient.unit
            name = ingredient.name
        }
    }
    
    private func saveAndClose() {
        var updated = ingredient
        updated.quantity = Double(quantity) ?? 0
        updated.unit = unit
        updated.name = name
        onSave(updated)
    }
    
    private func goToNextField() {
        switch editingField {
        case .quantity: editingField = .unit
        case .unit: editingField = .name
        case .name: editingField = .quantity
        }
    }
}

extension View {
    func ingredientPadButton(background: Color = Color(.systemGray5), foreground: Color = .primary) -> some View {
        self
            .font(.title2)
            .frame(width: 56, height: 44)
            .background(background)
            .foregroundColor(foreground)
            .cornerRadius(12)
    }
}

#Preview {
    // Create a sample recipe for preview
    let sampleRecipe = Recipe(
        remoteId: "sample",
        userId: "user",
        groupId: "group",
        houseHoldId: "household",
        name: "Sample Recipe",
        slug: "sample-recipe",
        image: nil,
        recipeDescription: "A sample recipe for testing",
        recipeServings: 4,
        recipeYieldQuantity: 0,
        recipeYield: "4 servings",
        totalTime: "30",
        prepTime: "10",
        cookTime: "20",
        performTime: "20",
        rating: nil,
        orgUrl: nil,
        dateAdded: "2024-01-01",
        dateUpdated: "2024-01-01",
        createdAt: "2024-01-01",
        lastMade: nil,
        update_at: "2024-01-01",
        lastModified: Date(),
        isFavorite: false,
        categories: [],
        tags: [],
        tools: [],
        ingredients: [
            Ingredient(orderIndex: 0, name: "Flour", quantity: 2, unit: IngredientUnit(name: "cups"), originalText: "2 cups flour", note: ""),
            Ingredient(orderIndex: 1, name: "Sugar", quantity: 1, unit: IngredientUnit(name: "cup"), originalText: "1 cup sugar", note: "")
        ],
        instructions: [
            Instruction(step: 1, text: "Mix flour and sugar"),
            Instruction(step: 2, text: "Bake at 350°F for 30 minutes")
        ]
    )
    
    let mockAPI = MockMealieAPIService()
    let user = User(id: "test", email: "test@test.com", group: "", household: "", groupId: "", groupSlug: "", householdId: "", householdSlug: "")
    
    EditRecipeView(mealieAPIService: mockAPI, recipe: sampleRecipe, isNewRecipe: false)
}
