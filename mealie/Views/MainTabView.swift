import SwiftUI
import SwiftData

struct MainTabView: View {
    
    @Environment(\.modelContext) var modelContext
    
    var mealieAPIService: MealieAPIServiceProtocol
    
    var body: some View {
        MainTabBodyView(modelContext: modelContext, mealieAPIService: mealieAPIService)
    }
} 

struct MainTabBodyView : View {
    
    var mealieAPIService: MealieAPIServiceProtocol
    
    init(modelContext: ModelContext, mealieAPIService: MealieAPIServiceProtocol) {
        self.mealieAPIService = mealieAPIService
        self.recipesViewModel = .init(modelContext: modelContext, mealieAPIService: mealieAPIService)
    }
    
    @State var recipesViewModel: RecipesViewModel
    
    var body: some View {
        
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
        .onAppear() {
            AppLogger.logRecipes(recipesViewModel.recipes, context: "MainTabView onAppear")
            Task {
                if self.recipesViewModel.shouldSyncRecipes() {
                    await self.recipesViewModel.syncRecipes()
                } else {
                    print("📱 Skipping recipe sync - last sync was recent")
                }
            }
        }
        
    }
    
}
