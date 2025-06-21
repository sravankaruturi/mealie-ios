import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @State private var hasSyncedFavorites = false
    
    var favorites: [Recipe] { recipes.filter { $0.isFavorite } }
    
    // Use lastMade instead of lastCookedDate, and dateAdded instead of lastModified
    var recentlyViewed: [Recipe] { 
        Array(recipes.sorted { parseAPIDateForSort($0.lastMade) > parseAPIDateForSort($1.lastMade) }.prefix(5)) 
    }
    var recentlyAdded: [Recipe] { 
        Array(recipes.sorted { parseAPIDateForSort($0.dateAdded) > parseAPIDateForSort($1.dateAdded) }.prefix(5)) 
    }
    
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
            .onAppear {
                print("🏠 HomeView appeared with \(recipes.count) recipes, hasSyncedFavorites: \(hasSyncedFavorites)")
                // Sync favorites from server on first load
                if !hasSyncedFavorites && !recipes.isEmpty {
                    Task {
                        await syncFavoritesFromServer()
                    }
                } else if recipes.isEmpty {
                    // If no recipes yet, wait a bit and try again
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                        if !hasSyncedFavorites && !recipes.isEmpty {
                            print("🔄 Retrying favorites sync after delay")
                            await syncFavoritesFromServer()
                        }
                    }
                }
            }
            .onChange(of: recipes.count) { oldCount, newCount in
                print("📊 Recipes count changed from \(oldCount) to \(newCount)")
                // If recipes were loaded and we haven't synced favorites yet, do it now
                if newCount > 0 && !hasSyncedFavorites {
                    print("🔄 Recipes loaded, triggering favorites sync")
                    Task {
                        await syncFavoritesFromServer()
                    }
                }
            }
        }
    }
    
    private func syncFavoritesFromServer() async {
        print("🔄 Starting favorites sync for \(recipes.count) recipes")
        do {
            try await MealieAPIService.shared.syncFavoritesFromServer(recipes: recipes)
            // Save the context to persist the favorite status changes and update the UI
            try? modelContext.save()
            hasSyncedFavorites = true
            print("✅ Favorites sync completed successfully")
        } catch {
            print("❌ Failed to sync favorites from server: \(error)")
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
