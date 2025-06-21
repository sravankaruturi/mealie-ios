import SwiftUI
import SwiftData

struct RecipeListView: View {
    @State var recipesViewModel: RecipesViewModel
    @State private var searchText: String = ""
    
    var filteredRecipes: [Recipe] {
        if searchText.isEmpty { return recipesViewModel.recipes }
        return recipesViewModel.recipes.filter { $0.name!.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredRecipes) { recipe in
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    RecipeCardView(recipe: recipe)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Recipes")
            .searchable(text: $searchText, prompt: "Search Recipes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
    }
}
