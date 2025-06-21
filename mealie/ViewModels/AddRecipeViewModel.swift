import Foundation
import SwiftUI
import SwiftData

@Observable
final class AddRecipeViewModel {
    var isLoading: Bool = false
    var error: String?
    var showSuccess: Bool = false
    
    let apiService: MealieAPIService
    let modelContext: ModelContext
    
    // Manual form fields (simplified)
    var name: String = ""
    var summary: String = ""
    var prepTime: String = ""
    var cookTime: String = ""
    var servings: String = ""
    var ingredients: [Ingredient] = []
    var instructions: [Instruction] = []
    
    init(apiService: MealieAPIService, modelContext: ModelContext) {
        self.apiService = apiService
        self.modelContext = modelContext
    }
    
    func addManualRecipe() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        // Build recipeData dictionary
        let recipeData: [String: Any] = [
            "name": name,
            "summary": summary,
            "prepTime": prepTime,
            "cookTime": cookTime,
            "servings": servings,
            // ...add ingredients and instructions
        ]
        do {
            let recipe = try await apiService.addRecipeManual(recipeData: recipeData)
            await MainActor.run {
                modelContext.insert(recipe)
                try? modelContext.save()
                showSuccess = true
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func addRecipeFromURL(_ url: URL) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let recipe = try await apiService.addRecipeFromURL(url: url)
            await MainActor.run {
                modelContext.insert(recipe)
                try? modelContext.save()
                showSuccess = true
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
} 
