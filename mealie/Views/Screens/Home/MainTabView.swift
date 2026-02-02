import SwiftUI
import SwiftData

/// Wrapper view that injects the model context into the tab body.
struct MainTabView: View {

    @Environment(\.modelContext) var modelContext

    var mealieAPIService: MealieAPIServiceProtocol
    
    var body: some View {
        MainTabBodyView(modelContext: modelContext, mealieAPIService: mealieAPIService)
    }
} 

/// The main tab bar with Home, Recipes, and Profile tabs. Triggers an initial recipe sync on appear.
struct MainTabBodyView : View {

    var mealieAPIService: MealieAPIServiceProtocol
    @Environment(NetworkMonitor.self) private var networkMonitor: NetworkMonitor?

    /// Creates the tab body, initializing the shared `RecipesViewModel`.
    init(modelContext: ModelContext, mealieAPIService: MealieAPIServiceProtocol) {
        self.mealieAPIService = mealieAPIService
        self.recipesViewModel = .init(modelContext: modelContext, mealieAPIService: mealieAPIService)
    }

    @State private var recipesViewModel: RecipesViewModel

    var body: some View {

        VStack(spacing: 0) {
            if let networkMonitor {
                OfflineBanner(networkMonitor: networkMonitor)
                    .animation(.easeInOut, value: networkMonitor.isConnected)
            }

            TabView {
                HomeView(mealieAPIService: self.mealieAPIService)
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                RecipeListView(mealieAPIService: self.mealieAPIService, recipesViewModel: recipesViewModel)
                    .tabItem {
                        Label("Recipes", systemImage: "book")
                    }
                ProfileView(recipesViewModel: recipesViewModel, mealieAPIService: self.mealieAPIService)
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
            }
        }
        .onAppear() {
            recipesViewModel.networkMonitor = networkMonitor
            Task {
                guard networkMonitor?.isConnected ?? true else {
                    AppLogger.debug(.sync, "Skipping recipe sync — offline")
                    return
                }
                if self.recipesViewModel.shouldSyncRecipes() {
                    await self.recipesViewModel.syncRecipes()
                } else {
                    AppLogger.debug(.sync, "Skipping recipe sync - last sync was recent")
                }
            }
        }

    }

}
