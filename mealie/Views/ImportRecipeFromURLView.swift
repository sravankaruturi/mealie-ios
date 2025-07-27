import SwiftUI
import SwiftData

struct ImportRecipeFromURLView: View {
    
    // We need to fetch the modelContext from the environment here.
    @Environment(\.modelContext) private var modelContext
    
    var mealieAPIService: MealieAPIServiceProtocol
    
    let onRecipeImported: ((String) -> Void)? // Callback for successful import
    let recipesViewModel: RecipesViewModel // Pass the existing view model

    var body: some View {
        // Then, we pass the context to the actual view content.
        // This ensures the viewModel is initialized correctly with the context.
        ImportRecipeFromURLContentView(
            modelContext: modelContext,
            mealieAPIService: mealieAPIService,
            recipesViewModel: recipesViewModel,
            onRecipeImported: onRecipeImported
        )
    }
}

struct ImportRecipeFromURLContentView: View {
    
    @Environment(\.dismiss) var dismiss
    
    // FIX: Use @State to create and own the @Observable object.
    @State private var viewModel: AddRecipeViewModel
    @State private var urlString: String = ""
    
    var mealieAPIService: MealieAPIServiceProtocol
    
    let onRecipeImported: ((String) -> Void)? // Callback for successful import
    let recipesViewModel: RecipesViewModel

    init(modelContext: ModelContext, mealieAPIService: MealieAPIServiceProtocol, recipesViewModel: RecipesViewModel, onRecipeImported: ((String) -> Void)? = nil) {
        // Initialize the State property with the modelContext passed from the parent.
        // Use the shared API service instance
        self.mealieAPIService = mealieAPIService
        // FIX: Correctly initialize the @State property within the initializer.
        _viewModel = State(initialValue: AddRecipeViewModel(
            apiService: mealieAPIService, 
            modelContext: modelContext,
            recipesViewModel: recipesViewModel
        ))
        self.recipesViewModel = recipesViewModel
        self.onRecipeImported = onRecipeImported
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                TextField("https://www.myrecipe.com", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                Button(action: {
                    if let url = URL(string: urlString) {
                        Task {
                            await viewModel.addRecipeFromURL(url)
                            
                            // Check if import was successful
                            if viewModel.showSuccess, let recipeSlug = viewModel.newRecipeSlug {
                                await MainActor.run {
                                    // Call the callback with the recipe slug
                                    onRecipeImported?(recipeSlug)
                                    dismiss()
                                }
                            }
                        }
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Import")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading || urlString.isEmpty)
                if let error = viewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                }
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Import from URL")
        }
    }
}
