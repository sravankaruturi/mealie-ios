import SwiftUI
import SwiftData

struct MainTabView: View {
    
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        MainTabBodyView(modelContext: modelContext)
    }
} 

struct MainTabBodyView : View {
    
    init(modelContext: ModelContext) {
        self.recipesViewModel = .init(modelContext: modelContext)
    }
    
    @State var recipesViewModel: RecipesViewModel
    
    var body: some View {
        
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            RecipeListView(recipesViewModel: recipesViewModel)
                .tabItem {
                    Label("Recipes", systemImage: "book")
                }
            AddRecipeView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle")
                }
            MealPlanView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            ProfileView(recipesViewModel: recipesViewModel)
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
