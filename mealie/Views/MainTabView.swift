import SwiftUI

struct MainTabView: View {
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
    }
} 