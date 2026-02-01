import SwiftUI
import SwiftData

/// Home screen showing favorite, recently viewed, and recently added recipe sections.
struct HomeView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @State private var hasSyncedFavorites = false

    /// The API service for syncing favorites from the server.
    var mealieAPIService: MealieAPIServiceProtocol

    /// Recipes the user has marked as favorites.
    var favorites: [Recipe] { recipes.filter { $0.isFavorite } }

    /// The 5 most recently made recipes, sorted by `lastMade` date.
    var recentlyViewed: [Recipe] {
        Array(recipes.sorted { parseAPIDateForSort($0.lastMade) > parseAPIDateForSort($1.lastMade) }.prefix(5))
    }
    /// The 5 most recently added recipes, sorted by `dateAdded`.
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
                                    NavigationLink(value: recipe) {
                                        RecipeCardView(recipe: recipe, mealieAPIService: self.mealieAPIService)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .frame(width: 180, height: 140)
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
                                    NavigationLink(value: recipe) {
                                        RecipeCardView(recipe: recipe, mealieAPIService: self.mealieAPIService)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .frame(width: 180, height: 140)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    if !recentlyAdded.isEmpty {
                        SectionHeader(title: "Recently Added")
                        
                        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
                            ForEach(Array(stride(from: 0, to: recentlyAdded.count, by: 2)), id: \.self) { index in
                                GridRow{
                                    NavigationLink(value: recentlyAdded[index]) {
                                        RecipeCardView(recipe: recentlyAdded[index], mealieAPIService: self.mealieAPIService)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .frame(width: 180, height: 140)
                                    
                                    if index + 1 < recentlyAdded.count {
                                        NavigationLink(value: recentlyAdded[index + 1]) {
                                            RecipeCardView(recipe: recentlyAdded[index + 1], mealieAPIService: self.mealieAPIService)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .frame(width: 180, height: 140)
                                    }
                                    
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Home")
            .onAppear {
                AppLogger.debug(.ui, "HomeView appeared with \(recipes.count) recipes, hasSyncedFavorites: \(hasSyncedFavorites)")
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
                            AppLogger.debug(.sync, "Retrying favorites sync after delay")
                            await syncFavoritesFromServer()
                        }
                    }
                }
            }
            .onChange(of: recipes.count) { oldCount, newCount in
                AppLogger.debug(.sync, "Recipes count changed from \(oldCount) to \(newCount)")
                // If recipes were loaded and we haven't synced favorites yet, do it now
                if newCount > 0 && !hasSyncedFavorites {
                    AppLogger.debug(.sync, "Recipes loaded, triggering favorites sync")
                    Task {
                        await syncFavoritesFromServer()
                    }
                }
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe, mealieAPIService: self.mealieAPIService)
            }
        }
    }
    
    /// Downloads favorite state from the server and updates local recipes.
    private func syncFavoritesFromServer() async {
        AppLogger.debug(.sync, "Starting favorites sync for \(recipes.count) recipes")
        do {
            try await self.mealieAPIService.syncFavoritesFromServer(recipes: recipes)
            // Save the context to persist the favorite status changes and update the UI
            try? modelContext.save()
            hasSyncedFavorites = true
            AppLogger.info(.sync, "Favorites sync completed successfully")
            
            // Show toast message when sync is completed for the first time
            ToastManager.shared.showInfo("Favorites synced successfully! Your saved recipes are now up to date.")
        } catch {
            AppLogger.error(.sync, "Failed to sync favorites from server: \(error)")
            ToastManager.shared.showError("Failed to sync favorites: \(error.localizedDescription)")
        }
    }
}

/// A styled section header used in the home screen.
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.horizontal)
    }
}
