//
//  MealieAPIServiceProtocol.swift
//  mealie
//
//  Created by Sravan Karuturi on 7/26/25.
//

import Foundation
import OpenAPIRuntime

/// Errors that can occur during Mealie API operations.
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

/// Available image size variants for recipe images.
enum ImageType: String, CaseIterable {
    case original = "original.webp"
    case minOriginal = "min-original.webp"
    case tinyOriginal = "tiny-original.webp"
}

/// Protocol defining all Mealie server API operations.
protocol MealieAPIServiceProtocol {

    // MARK: - Configuration
    /// Configures the client with the given server URL.
    /// - Parameter url: The base URL of the Mealie server.
    func setURL(_ url: URL)

    // MARK: - Authentication
    /// Authenticates with the server and returns an access token.
    /// - Parameters:
    ///   - username: The user's login name.
    ///   - password: The user's password.
    /// - Returns: An access token string.
    /// - Throws: `MealieAPIError` on authentication failure.
    func login(username: String, password: String) async throws -> String
    /// Fetches the current user's profile details.
    /// - Returns: A `User` model for the authenticated user.
    func fetchUserDetails() async throws -> User

    // MARK: - Recipes
    /// Fetches all recipes with pagination (N+1 detail calls).
    /// - Parameters:
    ///   - page: The page number to fetch.
    ///   - perPage: The number of recipes per page.
    /// - Returns: An array of fully-detailed `Recipe` objects.
    func fetchAllRecipes(page: Int, perPage: Int) async throws -> [Recipe]
    /// Fetches recipes, skipping detail calls for unchanged ones.
    /// - Parameters:
    ///   - existingRecipes: The locally cached recipes to compare against.
    ///   - page: The page number to fetch.
    ///   - perPage: The number of recipes per page.
    /// - Returns: An array of `Recipe` objects with only changed ones re-fetched.
    func fetchAllRecipesOptimized(existingRecipes: [Recipe], page: Int, perPage: Int) async throws -> [Recipe]
    /// Fetches full recipe details by slug.
    /// - Parameter slug: The recipe's URL slug identifier.
    /// - Returns: A fully-detailed `Recipe` object.
    func fetchRecipeDetails(slug: String) async throws -> Recipe
    /// Creates a new recipe with the given name and returns its generated slug.
    /// - Parameter recipeName: The name of the recipe to create
    /// - Returns: The generated slug for the newly created recipe
    /// - Throws: MealieAPIError if the recipe creation fails
    func addRecipeManual(recipeName: String) async throws -> String
    /// Submits a URL for server-side scraping and returns the generated slug.
    /// - Parameter url: The URL of the recipe to scrape.
    /// - Returns: The slug of the newly created recipe.
    func parseRecipeURL(url: URL) async throws -> String
    /// Scrapes a recipe from a URL and returns the full Recipe object.
    /// - Parameter url: The URL of the recipe to scrape.
    /// - Returns: The complete `Recipe` object.
    func addRecipeFromURL(url: URL) async throws -> Recipe
    /// Updates an existing recipe on the server.
    /// - Parameters:
    ///   - slug: The recipe's URL slug identifier.
    ///   - recipeData: The updated recipe data to send.
    func updateRecipe(slug: String, recipeData: Components.Schemas.Recipe_hyphen_Input) async throws
    /// Deletes a recipe by slug.
    /// - Parameter slug: The recipe's URL slug identifier.
    func deleteRecipe(slug: String) async throws
    /// Fetches all available ingredient units from the server.
    func fetchAllUnits() async throws -> [Components.Schemas.IngredientUnit_hyphen_Output]
    /// Fetches all available ingredient foods from the server.
    func fetchAllFoods() async throws -> [Components.Schemas.IngredientFood_hyphen_Output]

    // MARK: - Meal Plan
    /// Creates a new meal plan entry.
    /// - Parameter entryData: Dictionary containing the meal plan entry fields.
    func createMealPlanEntry(entryData: [String: Any]) async throws

    // MARK: - Images
    /// Constructs the image URL for a recipe.
    /// - Parameters:
    ///   - recipeId: The recipe's unique identifier.
    ///   - imageType: The desired image size variant.
    /// - Returns: The fully-qualified image URL, or `nil` if the server URL is not set.
    func getRecipeImageURL(recipeId: String, imageType: ImageType) -> URL?
    /// Constructs a Kingfisher-compatible image URL for a recipe.
    /// - Parameters:
    ///   - recipeId: The recipe's unique identifier.
    ///   - imageType: The desired image size variant.
    /// - Returns: The image URL suitable for Kingfisher, or `nil` if unavailable.
    func getRecipeImageURLForKingfisher(recipeId: String, imageType: ImageType) -> URL?

    // MARK: - Favorites
    /// Fetches the currently authenticated user's details.
    /// - Returns: The raw `UserOut` schema from the server.
    func getCurrentUser() async throws -> Components.Schemas.UserOut
    /// Marks a recipe as favorite on the server.
    /// - Parameter recipeSlug: The slug of the recipe to favorite.
    func addToFavorites(recipeSlug: String) async throws
    /// Removes a recipe from favorites on the server.
    /// - Parameter recipeSlug: The slug of the recipe to unfavorite.
    func removeFromFavorites(recipeSlug: String) async throws
    /// Fetches the current user's favorite recipes and ratings.
    func getCurrentUserFavorites() async throws -> Components.Schemas.UserRatings_UserRatingSummary_
    /// Syncs favorite status from server to local recipe models.
    /// - Parameter recipes: The local recipe models to update.
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
    
    /// Convenience method that creates a recipe and returns the full Recipe object.
    /// This provides consistency with addRecipeFromURL(_:) method.
    /// - Parameter recipeName: The name of the recipe to create
    /// - Returns: The complete Recipe object for the newly created recipe
    /// - Throws: MealieAPIError if the recipe creation fails
    func addRecipeManualAndFetch(recipeName: String) async throws -> Recipe {
        let slug = try await addRecipeManual(recipeName: recipeName)
        return try await fetchRecipeDetails(slug: slug)
    }
}


