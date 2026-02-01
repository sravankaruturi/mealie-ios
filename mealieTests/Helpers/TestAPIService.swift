import Foundation
import OpenAPIRuntime
@testable import mealIO

/// A fast, configurable mock of `MealieAPIServiceProtocol` for unit tests.
/// Unlike `MockMealieAPIService`, this has zero delays and fully configurable return values.
class TestAPIService: MealieAPIServiceProtocol {

    // MARK: - Configurable Behavior

    var shouldThrow: Error?
    var recipes: [Recipe] = []
    var recipeSlug: String = "test-slug"

    // MARK: - Call Counters

    var fetchAllRecipesCallCount = 0
    var fetchAllRecipesOptimizedCallCount = 0
    var fetchRecipeDetailsCallCount = 0
    var parseRecipeURLCallCount = 0
    var addRecipeManualCallCount = 0
    var updateRecipeCallCount = 0
    var deleteRecipeCallCount = 0
    var createMealPlanEntryCallCount = 0
    var fetchAllUnitsCallCount = 0
    var fetchAllFoodsCallCount = 0

    // MARK: - Configuration

    func setURL(_ url: URL) {}

    // MARK: - Authentication

    func login(username: String, password: String) async throws -> String {
        if let error = shouldThrow { throw error }
        return "mock-token"
    }

    func fetchUserDetails() async throws -> User {
        if let error = shouldThrow { throw error }
        return User.sampleData
    }

    // MARK: - Recipes

    func fetchAllRecipes(page: Int, perPage: Int) async throws -> [Recipe] {
        fetchAllRecipesCallCount += 1
        if let error = shouldThrow { throw error }
        return recipes
    }

    func fetchAllRecipesOptimized(existingRecipes: [Recipe], page: Int, perPage: Int) async throws -> [Recipe] {
        fetchAllRecipesOptimizedCallCount += 1
        if let error = shouldThrow { throw error }
        return recipes
    }

    func fetchRecipeDetails(slug: String) async throws -> Recipe {
        fetchRecipeDetailsCallCount += 1
        if let error = shouldThrow { throw error }
        return recipes.first(where: { $0.slug == slug }) ?? makeTestRecipe(slug: slug)
    }

    func addRecipeManual(recipeName: String) async throws -> String {
        addRecipeManualCallCount += 1
        if let error = shouldThrow { throw error }
        return recipeSlug
    }

    func parseRecipeURL(url: URL) async throws -> String {
        parseRecipeURLCallCount += 1
        if let error = shouldThrow { throw error }
        return recipeSlug
    }

    var addRecipeFromURLCallCount = 0

    func addRecipeFromURL(url: URL) async throws -> Recipe {
        addRecipeFromURLCallCount += 1
        if let error = shouldThrow { throw error }
        return recipes.first ?? makeTestRecipe()
    }

    func updateRecipe(slug: String, recipeData: Components.Schemas.Recipe_hyphen_Input) async throws {
        updateRecipeCallCount += 1
        if let error = shouldThrow { throw error }
    }

    func deleteRecipe(slug: String) async throws {
        deleteRecipeCallCount += 1
        if let error = shouldThrow { throw error }
    }

    func fetchAllUnits() async throws -> [Components.Schemas.IngredientUnit_hyphen_Output] {
        fetchAllUnitsCallCount += 1
        if let error = shouldThrow { throw error }
        return []
    }

    func fetchAllFoods() async throws -> [Components.Schemas.IngredientFood_hyphen_Output] {
        fetchAllFoodsCallCount += 1
        if let error = shouldThrow { throw error }
        return []
    }

    // MARK: - Meal Plan

    func createMealPlanEntry(entryData: [String: Any]) async throws {
        createMealPlanEntryCallCount += 1
        if let error = shouldThrow { throw error }
    }

    // MARK: - Images

    func getRecipeImageURL(recipeId: String, imageType: ImageType) -> URL? {
        return URL(string: "https://example.com/image.webp")
    }

    func getRecipeImageURLForKingfisher(recipeId: String, imageType: ImageType) -> URL? {
        return URL(string: "https://example.com/image.webp")
    }

    // MARK: - Favorites

    func getCurrentUser() async throws -> Components.Schemas.UserOut {
        if let error = shouldThrow { throw error }
        throw MealieAPIError.networkError(NSError(domain: "TestAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "getCurrentUser not configured for this test"]))
    }

    func addToFavorites(recipeSlug: String) async throws {
        if let error = shouldThrow { throw error }
    }

    func removeFromFavorites(recipeSlug: String) async throws {
        if let error = shouldThrow { throw error }
    }

    func getCurrentUserFavorites() async throws -> Components.Schemas.UserRatings_UserRatingSummary_ {
        if let error = shouldThrow { throw error }
        throw MealieAPIError.networkError(NSError(domain: "TestAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "getCurrentUserFavorites not configured for this test"]))
    }

    func syncFavoritesFromServer(recipes: [Recipe]) async throws {
        if let error = shouldThrow { throw error }
    }
}
