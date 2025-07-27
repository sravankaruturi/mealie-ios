////
////  ExampleUsage.swift
////  mealie
////
////  Created by Sravan Karuturi on 7/26/25.
////
//
//import Foundation
//import SwiftUI
//
//// MARK: - Example ViewModel with Dependency Injection
//@Observable
//final class ExampleRecipesViewModel {
//    
//    var recipes: [Recipe] = []
//    var isLoading = false
//    var error: String?
//    
//    private let apiService: MealieAPIServiceProtocol
//    
//    // Dependency injection through initializer
//    init(apiService: MealieAPIServiceProtocol = MealieAPIService.shared) {
//        self.apiService = apiService
//    }
//    
//    func loadRecipes() async {
//        isLoading = true
//        error = nil
//        
//        do {
//            recipes = try await apiService.fetchAllRecipes()
//        } catch {
//            self.error = error.localizedDescription
//        }
//        
//        isLoading = false
//    }
//    
//    func toggleFavorite(for recipe: Recipe) async {
//        do {
//            if recipe.isFavorite {
//                try await apiService.removeFromFavorites(recipeSlug: recipe.slug)
//            } else {
//                try await apiService.addToFavorites(recipeSlug: recipe.slug)
//            }
//            recipe.isFavorite.toggle()
//        } catch {
//            self.error = error.localizedDescription
//        }
//    }
//}
//
//// MARK: - Example SwiftUI View with Preview
//struct ExampleRecipesView: View {
//    @State private var viewModel: ExampleRecipesViewModel
//    
//    init(apiService: MealieAPIServiceProtocol = MealieAPIService.shared) {
//        _viewModel = State(initialValue: ExampleRecipesViewModel(apiService: apiService))
//    }
//    
//    var body: some View {
//        NavigationView {
//            List(viewModel.recipes, id: \.slug) { recipe in
//                VStack(alignment: .leading) {
//                    Text(recipe.name ?? "Unknown Recipe")
//                        .font(.headline)
//                    
//                    Text(recipe.recipeDescription)
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                    
//                    HStack {
//                        Text("\(recipe.recipeServings) servings")
//                            .font(.caption)
//                        
//                        Spacer()
//                        
//                        Button(action: {
//                            Task {
//                                await viewModel.toggleFavorite(for: recipe)
//                            }
//                        }) {
//                            Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
//                                .foregroundColor(recipe.isFavorite ? .red : .gray)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Recipes")
//            .task {
//                await viewModel.loadRecipes()
//            }
//            .overlay {
//                if viewModel.isLoading {
//                    ProgressView("Loading recipes...")
//                }
//            }
//            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
//                Button("OK") {
//                    viewModel.error = nil
//                }
//            } message: {
//                if let error = viewModel.error {
//                    Text(error)
//                }
//            }
//        }
//    }
//}
//
//// MARK: - SwiftUI Previews
//#Preview("Real API Service") {
//    ExampleRecipesView(apiService: MealieAPIService.shared)
//}
//
//#Preview("Mock API Service") {
//    let mockService = MockMealieAPIService()
//    // Set up some mock favorites for testing
//    mockService.setMockFavorites(["spaghetti-carbonara", "chocolate-cake"])
//    
//    return ExampleRecipesView(apiService: mockService)
//}
//
//#Preview("Mock API Service - Empty State") {
//    let mockService = MockMealieAPIService()
//    // Clear all mock data to test empty state
//    mockService.clearMockData()
//    
//    return ExampleRecipesView(apiService: mockService)
//}
//
//// MARK: - Migration Guide for Existing ViewModels
///*
// 
// To migrate existing ViewModels to use dependency injection:
// 
// 1. Change the direct reference:
//    BEFORE: let apiService: MealieAPIService = .shared
//    AFTER:  private let apiService: MealieAPIServiceProtocol
// 
// 2. Add dependency injection to initializer:
//    BEFORE: init(modelContext: ModelContext) {
//    AFTER:  init(modelContext: ModelContext, apiService: MealieAPIServiceProtocol = MealieAPIService.shared) {
// 
// 3. Update the property:
//    BEFORE: let apiService: MealieAPIService = .shared
//    AFTER:  self.apiService = apiService
// 
// Example migration for RecipesViewModel:
// 
// @Observable
// final class RecipesViewModel {
//     var isSyncing: Bool = false
//     var error: String?
//     let modelContext: ModelContext
//     private let apiService: MealieAPIServiceProtocol  // Changed
//     var recipes: [Recipe]
//     var lastSyncTime: Date?
//     
//     init(modelContext: ModelContext, apiService: MealieAPIServiceProtocol = MealieAPIService.shared) {  // Added parameter
//         self.modelContext = modelContext
//         self.apiService = apiService  // Set the injected service
//         self.recipes = (try? modelContext.fetch(FetchDescriptor<Recipe>())) ?? []
//         AppLogger.logRecipes(self.recipes, context: "RecipesViewModel Initialized")
//     }
//     
//     // ... rest of the implementation remains the same
// }
// 
// */ 
