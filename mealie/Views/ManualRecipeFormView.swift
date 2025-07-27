import SwiftUI
import SwiftData

struct ManualRecipeFormView: View {
    // 1. Get the modelContext from the environment.
    @Environment(\.modelContext) private var modelContext
    
    var mealieAPIService: MealieAPIServiceProtocol

    var body: some View {
        // 2. Pass the context to the content view.
        ManualRecipeFormContentView(modelContext: modelContext, mealieAPIService: mealieAPIService)
    }
}

struct ManualRecipeFormContentView: View {
    // FIX: Use @State to create and own the @Observable view model.
    @State private var viewModel: AddRecipeViewModel
    @Environment(\.dismiss) var dismiss
    
//    var mealieAPIService: MealieAPIServiceProtocol

    init(modelContext: ModelContext, mealieAPIService: MealieAPIServiceProtocol) {
        // FIX: Correctly initialize the @State property within the initializer.
        _viewModel = State(initialValue: AddRecipeViewModel(apiService: mealieAPIService, modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Recipe Info")) {
                    TextField("Name", text: $viewModel.name)
                    TextField("Summary", text: $viewModel.summary)
                    TextField("Prep Time", text: $viewModel.prepTime)
                    TextField("Cook Time", text: $viewModel.cookTime)
                    TextField("Servings", text: $viewModel.servings)
                }
                Section(header: Text("Ingredients")) {
                    // Use a ForEach loop that binds to the viewModel's ingredients array.
                    ForEach($viewModel.ingredients) { $ingredient in
                        HStack {
                            TextField("2", value: $ingredient.quantity, formatter: NumberFormatter())
                                .frame(width: 40)
                            Picker("Unit", selection: $ingredient.unit) {
                                Text(ingredient.unit.name).tag(ingredient.unit)
                                // You may want to provide a list of units here
                            }
                            .frame(width: 80)
                            TextField("flour", text: $ingredient.name)
                        }
                    }
                    .onDelete { viewModel.ingredients.remove(atOffsets: $0) }
                    
                    Button("Add Ingredient") {
                        viewModel.ingredients.append(Ingredient(orderIndex: viewModel.ingredients.count, name: "", quantity: 0, unit: IngredientUnit(name: ""), originalText: "", note: ""))
                    }
                }
                Section(header: Text("Instructions")) {
                    // Use a ForEach loop that binds to the viewModel's instructions array.
                    ForEach($viewModel.instructions) { $instruction in
                        TextField("Mix ingredients...", text: $instruction.text)
                    }
                     .onDelete { viewModel.instructions.remove(atOffsets: $0) }

                    Button("Add Step") {
                        viewModel.instructions.append(Instruction(step: viewModel.instructions.count + 1, text: ""))
                    }
                }
            }
            .navigationTitle("Add Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.addManualRecipe()
                            dismiss()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
}
