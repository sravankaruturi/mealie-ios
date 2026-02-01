import Foundation
import SwiftUI
import SwiftData

@Observable
/// Manages adding new recipes from URLs or manual entry.
final class AddRecipeViewModel {
    /// Whether a recipe import/creation operation is in progress.
    var isLoading: Bool = false
    /// The most recent error from an add operation.
    var error: String?
    var showSuccess: Bool = false
    /// The successfully added recipe slug, if any.
    var newRecipeSlug: String?
    
    let apiService: MealieAPIServiceProtocol
    let modelContext: ModelContext
    let recipesViewModel: RecipesViewModel? // Optional for manual recipes
    
    /// Creates a view model for adding recipes.
    init(apiService: MealieAPIServiceProtocol, modelContext: ModelContext, recipesViewModel: RecipesViewModel? = nil) {
        self.apiService = apiService
        self.modelContext = modelContext
        self.recipesViewModel = recipesViewModel
    }
    
    /// Imports a recipe by URL, saves it locally, and syncs with the server.
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
