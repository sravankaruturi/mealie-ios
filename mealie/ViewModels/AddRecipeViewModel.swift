import Foundation
import SwiftUI
import SwiftData

@Observable
final class AddRecipeViewModel {
    var isLoading: Bool = false
    var error: String?
    var showSuccess: Bool = false
    var newRecipeSlug: String? // For navigation to the new recipe
    
    let apiService: MealieAPIServiceProtocol
    let modelContext: ModelContext
    let recipesViewModel: RecipesViewModel? // Optional for manual recipes
    
    // Manual form fields (simplified)
    var name: String = ""
    var summary: String = ""
    var prepTime: String = ""
    var cookTime: String = ""
    var servings: String = ""
    var ingredients: [Ingredient] = []
    var instructions: [Instruction] = []
    
    init(apiService: MealieAPIServiceProtocol, modelContext: ModelContext, recipesViewModel: RecipesViewModel? = nil) {
        self.apiService = apiService
        self.modelContext = modelContext
        self.recipesViewModel = recipesViewModel
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
        await MainActor.run {
            isLoading = true
            error = nil
            newRecipeSlug = nil
        }
        
        do {
            // Step 1: Parse the URL to get the recipe slug
            let recipeSlug = try await apiService.parseRecipeURL(url: url)
            
            // Step 2: Fetch the specific recipe details (much more efficient than full sync)
            let recipe = try await apiService.fetchRecipeDetails(slug: recipeSlug)
            
            // Step 3: Add to local storage and store the recipe slug for navigation
            await MainActor.run {
                // Add to local storage
                modelContext.insert(recipe)
                try? modelContext.save()
                
                // Update the recipes list in the view model
                recipesViewModel?.recipes.append(recipe)
                
                self.newRecipeSlug = recipeSlug
                self.showSuccess = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
} 
