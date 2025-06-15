import SwiftUI
import SwiftData

struct ImportRecipeFromURLView: View {
    // We need to fetch the modelContext from the environment here.
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        // Then, we pass the context to the actual view content.
        // This ensures the viewModel is initialized correctly with the context.
        ImportRecipeFromURLContentView(modelContext: modelContext)
    }
}

struct ImportRecipeFromURLContentView: View {
    // FIX: Use @State to create and own the @Observable object.
    @State private var viewModel: AddRecipeViewModel
    @Environment(\.dismiss) var dismiss
    @State private var urlString: String = ""

    init(modelContext: ModelContext) {
        // Initialize the State property with the modelContext passed from the parent.
        // NOTE: This assumes you have a MealieAPIService and it can be initialized.
        // You may need to adjust where the serverURL comes from.
        let apiService = MealieAPIService(serverURL: URL(string: "http://localhost:9000")!)
        // FIX: Correctly initialize the @State property within the initializer.
        _viewModel = State(initialValue: AddRecipeViewModel(apiService: apiService, modelContext: modelContext))
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
                            dismiss()
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
                .disabled(viewModel.isLoading)
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
