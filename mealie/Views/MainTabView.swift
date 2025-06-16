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
            RecipeListView()
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
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .onAppear() {
            Task {
                try? await self.recipesViewModel.syncRecipes()
            }
        }
        
    }
    
}
