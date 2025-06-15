import Foundation
import SwiftData

@Observable
final class MealPlanViewModel {
    
    var error: String?
    var isLoading: Bool = false
    let apiService: MealieAPIService
    let modelContext: ModelContext
    
    init(apiService: MealieAPIService, modelContext: ModelContext) {
        self.apiService = apiService
        self.modelContext = modelContext
    }
    
    func createMealPlanEntry(date: Date, mealType: String, recipe: Recipe) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        let entryData: [String: Any] = [
            "date": date,
            "mealType": mealType,
            "recipeId": recipe.remoteId
        ]
        do {
            try await apiService.createMealPlanEntry(entryData: entryData)
            // Insert locally
            let entry = MealPlanEntry(date: date, mealType: mealType, recipe: recipe)
            modelContext.insert(entry)
            try modelContext.save()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func generateShoppingList(for entries: [MealPlanEntry]) -> [String: Double] {
        // Consolidate all ingredients by name and sum quantities
        var shoppingList: [String: Double] = [:]
        for entry in entries {
            guard let recipe = entry.recipe else { continue }
            for ingredient in recipe.ingredients {
                shoppingList[ingredient.name, default: 0] += ingredient.quantity
            }
        }
        return shoppingList
    }
} 
