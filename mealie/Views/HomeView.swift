import SwiftUI
import SwiftData

struct HomeView: View {
    // FIX 1: Explicitly specify the root type <Recipe> for the SortDescriptor.
    @Query(sort: [SortDescriptor<Recipe>(\.name)]) var recipes: [Recipe]
    
    var favorites: [Recipe] { recipes.filter { $0.isFavorite } }
    
    // FIX 2: Convert the ArraySlice from .prefix() back to a standard Array.
    var recentlyViewed: [Recipe] { Array(recipes.sorted { ($0.lastCookedDate ?? .distantPast) > ($1.lastCookedDate ?? .distantPast) }.prefix(5)) }
    var recentlyAdded: [Recipe] { Array(recipes.sorted { $0.lastModified > $1.lastModified }.prefix(5)) }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !favorites.isEmpty {
                        SectionHeader(title: "Favorites")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(favorites) { recipe in
                                    RecipeCardView(recipe: recipe)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    if !recentlyViewed.isEmpty {
                        SectionHeader(title: "Recently Viewed")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(recentlyViewed) { recipe in
                                    RecipeCardView(recipe: recipe)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    if !recentlyAdded.isEmpty {
                        SectionHeader(title: "Recently Added")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                            ForEach(recentlyAdded) { recipe in
                                RecipeCardView(recipe: recipe)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Home")
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.horizontal)
    }
}
