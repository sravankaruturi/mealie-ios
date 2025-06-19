import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    
    // Remove favorites for now since isFavorite doesn't exist
    // var favorites: [Recipe] { recipes.filter { $0.isFavorite } }
    
    // Helper function to parse date string to Date for sorting
    private func parseDate(_ dateString: String?) -> Date {
        guard let dateString = dateString else { return .distantPast }
        
        // Try ISO8601 format first
        if let date = ISO8601DateFormatter().date(from: dateString) {
            return date
        }
        
        // Try date-only format (YYYY-MM-DD)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        
        return .distantPast
    }
    
    // Use lastMade instead of lastCookedDate, and dateAdded instead of lastModified
    var recentlyViewed: [Recipe] { 
        Array(recipes.sorted { parseDate($0.lastMade) > parseDate($1.lastMade) }.prefix(5)) 
    }
    var recentlyAdded: [Recipe] { 
        Array(recipes.sorted { parseDate($0.dateAdded) > parseDate($1.dateAdded) }.prefix(5)) 
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Remove favorites section for now
                    // if !favorites.isEmpty {
                    //     SectionHeader(title: "Favorites")
                    //     ScrollView(.horizontal, showsIndicators: false) {
                    //         HStack(spacing: 16) {
                    //             ForEach(favorites) { recipe in
                    //                 RecipeCardView(recipe: recipe)
                    //             }
                    //         }
                    //         .padding(.horizontal)
                    //     }
                    // }
                    
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
