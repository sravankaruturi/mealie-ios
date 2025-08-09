//
//  MealieAPIServiceProtocol.swift
//  mealie
//
//  Created by Sravan Karuturi on 7/26/25.
//

import Foundation
import OpenAPIRuntime

enum MealieAPIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case unauthorized
    case insecureConnection
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid server URL."
        case .networkError(let err): return err.localizedDescription
        case .decodingError(let err): return "Failed to decode response: \(err.localizedDescription)"
        case .unauthorized: return "Unauthorized. Please check your credentials."
        case .insecureConnection: return "Insecure connection. Allow HTTP or self-signed certificate?"
        case .custom(let msg): return msg
        }
    }
}

enum ImageType: String, CaseIterable {
    case original = "original.webp"
    case minOriginal = "min-original.webp"
    case tinyOriginal = "tiny-original.webp"
}

protocol MealieAPIServiceProtocol {
    
    // MARK: - Configuration
    func setURL(_ url: URL)
    
    // MARK: - Authentication
    func login(username: String, password: String) async throws -> String
    func fetchUserDetails() async throws -> User
    
    // MARK: - Recipes
    func fetchAllRecipes(page: Int, perPage: Int) async throws -> [Recipe]
    func fetchAllRecipesOptimized(existingRecipes: [Recipe], page: Int, perPage: Int) async throws -> [Recipe]
    func fetchRecipeDetails(slug: String) async throws -> Recipe
    func addRecipeManual(recipeData: [String: Any]) async throws -> Recipe
    func parseRecipeURL(url: URL) async throws -> String
    func addRecipeFromURL(url: URL) async throws -> Recipe
    func updateRecipe(slug: String, recipeData: Components.Schemas.Recipe_hyphen_Input) async throws
    func deleteRecipe(slug: String) async throws
    
    // MARK: - Meal Plan
    func createMealPlanEntry(entryData: [String: Any]) async throws
    
    // MARK: - Images
    func getRecipeImageURL(recipeId: String, imageType: ImageType) -> URL?
    func getRecipeImageURLForKingfisher(recipeId: String, imageType: ImageType) -> URL?
    
    // MARK: - Favorites
    func getCurrentUser() async throws -> Components.Schemas.UserOut
    func addToFavorites(recipeSlug: String) async throws
    func removeFromFavorites(recipeSlug: String) async throws
    func getCurrentUserFavorites() async throws -> Components.Schemas.UserRatings_UserRatingSummary_
    func syncFavoritesFromServer(recipes: [Recipe]) async throws
}

// MARK: - Convenience Methods with Default Parameters
// Note: Swift protocols don't support default arguments, so we provide convenience methods
// that call the required protocol methods with default values.
extension MealieAPIServiceProtocol {
    func fetchAllRecipes() async throws -> [Recipe] {
        return try await fetchAllRecipes(page: 1, perPage: 50)
    }
    
    func fetchAllRecipesOptimized(existingRecipes: [Recipe]) async throws -> [Recipe] {
        return try await fetchAllRecipesOptimized(existingRecipes: existingRecipes, page: 1, perPage: 50)
    }
    
    func getRecipeImageURL(recipeId: String) -> URL? {
        return getRecipeImageURL(recipeId: recipeId, imageType: .original)
    }
    
    func getRecipeImageURLForKingfisher(recipeId: String) -> URL? {
        return getRecipeImageURLForKingfisher(recipeId: recipeId, imageType: .original)
    }
}


