import SwiftUI
import SwiftData

struct RecipeListView: View {
    // FIX: Explicitly specify the root type <Recipe> for the SortDescriptor.
    @Query(sort: [SortDescriptor<Recipe>(\.name)]) var recipes: [Recipe]
    @State private var searchText: String = ""
    
    var filteredRecipes: [Recipe] {
        if searchText.isEmpty { return recipes }
        return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
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
        }
    }
}
