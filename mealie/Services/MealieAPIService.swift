import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

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

final class MealieAPIService {
    
    public static let shared = MealieAPIService(serverURL: nil)
    
    private(set) var serverURL: URL?
    private var session: URLSession
    var client: Client?
    
    init(serverURL: URL?) {
        
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
        
        if serverURL != nil {
            setURL(serverURL!)
        }else {
            print("Server URL is Null")
        }

    }
    
    public func setURL(_ url: URL) {
        self.serverURL = url
        self.client = Client(
            serverURL: url,
            transport: URLSessionTransport(),
            middlewares: [AuthenticationMiddleware()]
        )
    }
    
    // MARK: - Authentication
    func login(username: String, password: String) async throws -> String {
        
        let requestBody = Components.Schemas.Body_get_token_api_auth_token_post(
            username: username,
            password: password,
            remember_me: true
        )
        
        let input = Operations.get_token_api_auth_token_post.Input(
            body: .urlEncodedForm(requestBody)
            )
        
        do {
            let output = try await client!.get_token_api_auth_token_post(input)
            
            switch output {
                
            case .ok(let response):
                let jsonResponse = try response.body.json
                
                guard let token = jsonResponse.access_token else {
                    throw MealieAPIError.custom("No access_token in response.")
                }
                return token
                
            case .unprocessableContent(let response):
                // Handle validation errors (422).
                // You can inspect 'response.body' for more details if needed.
                throw MealieAPIError.custom("Validation Error: \(response)")

            case .undocumented(let statusCode, _):
                // Handle any other status code not in the spec.
                if statusCode == 401 {
                    throw MealieAPIError.unauthorized
                } else {
                    throw MealieAPIError.networkError(NSError(domain: "HTTP error", code: statusCode))
                }
            }
        } catch let error as URLError {
            if error.code == .appTransportSecurityRequiresSecureConnection || error.code == .serverCertificateUntrusted {
                throw MealieAPIError.insecureConnection
            }
            throw MealieAPIError.networkError(error)
        } catch {
            // Catches decoding errors or other issues.
            throw MealieAPIError.networkError(error)
        }
    
    }
    
    // MARK: - Recipes
    func fetchAllRecipes(page: Int = 1, perPage: Int = 50) async throws -> [Recipe] {
        
        let input = Operations.get_all_api_recipes_get.Input(query: .init() )
        let output = try await self.client!.get_all_api_recipes_get(input)
        
        switch output {
        case .ok(let response):
            
            let paginationResponse = try response.body.json
            
            let recipeSummaries = paginationResponse.items
            
            var recipes: [Recipe] = []
            
            for recipeSummary in recipeSummaries {
                
                guard let slug = recipeSummary.slug else { continue }
                
                let recipe = try await fetchRecipeDetails(slug: slug)
                recipes.append(recipe)
                
            }
            
            
            return recipes
        default:
            throw MealieAPIError.custom("Failed to fetch recipes.")
        }
        
    }
    
    /// Optimized recipe fetching that only downloads full details for updated recipes
    func fetchAllRecipesOptimized(existingRecipes: [Recipe], page: Int = 1, perPage: Int = 50) async throws -> [Recipe] {
        
        let input = Operations.get_all_api_recipes_get.Input(query: .init() )
        let output = try await self.client!.get_all_api_recipes_get(input)
        
        switch output {
        case .ok(let response):
            
            let paginationResponse = try response.body.json
            let recipeSummaries = paginationResponse.items
            
            // Create a map of existing recipes by slug for quick lookup
            let existingRecipesMap = Dictionary(uniqueKeysWithValues: existingRecipes.map { ($0.slug, $0) })
            
            var updatedRecipes: [Recipe] = []
            var cachedCount = 0
            var fetchedCount = 0
            var newCount = 0
            
            for recipeSummary in recipeSummaries {
                guard let slug = recipeSummary.slug else { continue }
                
                // Check if we have this recipe locally
                if let existingRecipe = existingRecipesMap[slug] {
                    // Compare timestamps to see if we need to update by parsing them into Date objects
                    let serverDate = parseAPIDate(recipeSummary.dateUpdated)
                    let localDate = parseAPIDate(existingRecipe.dateUpdated)

                    let areDatesEffectivelyEqual: Bool
                    if let serverDate = serverDate, let localDate = localDate {
                        // Compare with a 1-second tolerance to account for any minor precision differences
                        areDatesEffectivelyEqual = abs(serverDate.timeIntervalSince(localDate)) < 1.0
                    } else {
                        // If one is nil and the other isn't, they are not equal. If both are nil, they are equal.
                        areDatesEffectivelyEqual = (serverDate == nil && localDate == nil)
                    }

                    if areDatesEffectivelyEqual && !existingRecipe.ingredients.isEmpty && !existingRecipe.instructions.isEmpty {
                        // Recipe hasn't changed, use existing data
                        updatedRecipes.append(existingRecipe)
                        cachedCount += 1
                    } else {
                        // Recipe has been updated, fetch full details
                        print("Fetching updated recipe: \(existingRecipe.name ?? "Unknown") (server: \(recipeSummary.dateUpdated ?? "nil"), local: \(existingRecipe.dateUpdated ?? "nil"))")
                        let updatedRecipe = try await fetchRecipeDetails(slug: slug)
                        // Preserve favorite state
                        updatedRecipe.isFavorite = existingRecipe.isFavorite
                        updatedRecipes.append(updatedRecipe)
                        fetchedCount += 1
                    }
                } else {
                    // New recipe, fetch full details
                    print("Fetching new recipe: \(recipeSummary.name ?? "Unknown")")
                    let newRecipe = try await fetchRecipeDetails(slug: slug)
                    updatedRecipes.append(newRecipe)
                    newCount += 1
                }
            }
            
            print("📊 Recipe sync stats: \(cachedCount) cached, \(fetchedCount) updated, \(newCount) new")
            
            return updatedRecipes
            
        default:
            throw MealieAPIError.custom("Failed to fetch recipes.")
        }
    }
    
    /// Helper method to parse date strings from the API
    private func parseDateString(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        // Try ISO8601 format first (most common for API timestamps)
        if let date = ISO8601DateFormatter().date(from: dateString) {
            return date
        }
        
        // Try date-only format (YYYY-MM-DD)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: dateString) {
            return date
        }
        
        return nil
    }
    
    /// Helper method to normalize timestamps for comparison
    private func normalizeTimestamp(_ timestamp: String) -> String {
        // If empty, return as is
        guard !timestamp.isEmpty else { return timestamp }
        
        // Try to parse as ISO8601 and reformat consistently
        if let date = ISO8601DateFormatter().date(from: timestamp) {
            let formatter = ISO8601DateFormatter()
            return formatter.string(from: date)
        }
        
        // If we can't parse it, return the original string
        return timestamp
    }
    
    func fetchRecipeDetails(slug: String) async throws -> Recipe {
        // GET /api/recipes/{recipe_slug}
        let input = Operations.get_one_api_recipes__slug__get.Input(path: .init(slug: slug))
        let output = try await client!.get_one_api_recipes__slug__get(input)
        
        switch output {
        case .ok(let response):
            
            let data: Components.Schemas.Recipe_hyphen_Output = try response.body.json
            
            let recipe = Recipe(output: data)
            
            return recipe
            
        default:
            throw MealieAPIError.custom("Failed to fetch recipe details.")
        }
    }
    
    func addRecipeManual(recipeData: [String: Any]) async throws -> Recipe {
        // POST /api/recipes
        throw MealieAPIError.custom("Not implemented")
    }
    
    func addRecipeFromURL(url: URL) async throws -> Recipe {
        // POST /api/recipes/create-from-url
        throw MealieAPIError.custom("Not implemented")
    }
    
    // MARK: - Meal Plan
    func createMealPlanEntry(entryData: [String: Any]) async throws {
        // POST /api/meal-plans
        throw MealieAPIError.custom("Not implemented")
    }
    
    // MARK: - Images
    func getRecipeImageURL(recipeId: String, imageType: ImageType = .original) -> URL? {
        guard let serverURL = serverURL else { return nil }
        return serverURL.appendingPathComponent("api/media/recipes/\(recipeId)/images/\(imageType.rawValue)")
    }
    
//    // MARK: - OpenAPI Generated Image Functions
//    func fetchRecipeImageOpenAPI(recipeId: String, imageType: ImageType = .original) async throws -> Data {
//        guard let client = client else {
//            throw MealieAPIError.custom("Client not initialized")
//        }
//        
//        let input = Operations.get_recipe_img_api_media_recipes__recipe_id__images__file_name__get.Input(
//            path: .init(
//                recipe_id: recipeId,
//                file_name: Components.Schemas.ImageType(rawValue: imageType.rawValue) ?? .min_hyphen_original_period_webp
//            )
//        )
//        
//        let output = try await client.get_recipe_img_api_media_recipes__recipe_id__images__file_name__get(input)
//        
//        switch output {
//        case .ok(let response):
//            // The response body should contain the image data
//            // TODO: I think the OpenAPI Spec is wrong here. It says it will return a Json file. But I get the file.
//            return response.body
//        default:
//            throw MealieAPIError.custom("Failed to fetch recipe image")
//        }
//    }
    
    // MARK: - Kingfisher Integration
    func getRecipeImageURLForKingfisher(recipeId: String, imageType: ImageType = .original) -> URL? {
        return getRecipeImageURL(recipeId: recipeId, imageType: imageType)
    }
    
    // MARK: - Favorites
    func getCurrentUser() async throws -> Components.Schemas.UserOut {
        guard let client = client else {
            throw MealieAPIError.custom("Client not initialized")
        }
        
        let input = Operations.get_logged_in_user_api_users_self_get.Input()
        
        let output = try await client.get_logged_in_user_api_users_self_get(input)
        
        switch output {
        case .ok(let response):
            return try response.body.json
        default:
            throw MealieAPIError.custom("Failed to get current user")
        }
    }
    
    func addToFavorites(recipeSlug: String) async throws {
        guard let client = client else {
            throw MealieAPIError.custom("Client not initialized")
        }
        
        // Get the current user ID
        let currentUser = try await getCurrentUser()
        
        let input = Operations.add_favorite_api_users__id__favorites__slug__post.Input(
            path: .init(
                id: currentUser.id,
                slug: recipeSlug
            )
        )
        
        let output = try await client.add_favorite_api_users__id__favorites__slug__post(input)
        
        switch output {
        case .ok:
            // Successfully added to favorites
            break
        default:
            throw MealieAPIError.custom("Failed to add recipe to favorites")
        }
    }
    
    func removeFromFavorites(recipeSlug: String) async throws {
        guard let client = client else {
            throw MealieAPIError.custom("Client not initialized")
        }
        
        // Get the current user ID
        let currentUser = try await getCurrentUser()
        
        let input = Operations.remove_favorite_api_users__id__favorites__slug__delete.Input(
            path: .init(
                id: currentUser.id,
                slug: recipeSlug
            )
        )
        
        let output = try await client.remove_favorite_api_users__id__favorites__slug__delete(input)
        
        switch output {
        case .ok:
            // Successfully removed from favorites
            break
        default:
            throw MealieAPIError.custom("Failed to remove recipe from favorites")
        }
    }
    
    func getCurrentUserFavorites() async throws -> Components.Schemas.UserRatings_UserRatingSummary_ {
        guard let client = client else {
            throw MealieAPIError.custom("Client not initialized")
        }
        
        let input = Operations.get_logged_in_user_favorites_api_users_self_favorites_get.Input()
        
        let output = try await client.get_logged_in_user_favorites_api_users_self_favorites_get(input)
        
        switch output {
        case .ok(let response):
            return try response.body.json
        default:
            throw MealieAPIError.custom("Failed to get user favorites")
        }
    }
    
    /// Sync favorites from server to local recipes
    func syncFavoritesFromServer(recipes: [Recipe]) async throws {
        print("🔄 Starting favorites sync...")
        let serverFavorites = try await getCurrentUserFavorites()
        
        print("📊 Server favorites response: \(serverFavorites.ratings.count) ratings")
//        
        // Debug: Print the structure of the first rating to understand the data
        if let firstRating = serverFavorites.ratings.first {
            print("🔍 First rating structure: \(firstRating)")
        }
        
        // Create a set of favorite recipe slugs from server
        let serverFavoriteIds = Set<String>(serverFavorites.ratings.compactMap { rating -> String? in
            
            guard let isFav = rating.isFavorite, isFav else {
                return nil
            }
            
            // Try different possible field names for the recipe identifier
            let recipeId = rating.recipeId
            print("❤️ Found favorite recipe: \(recipeId)")
            return recipeId
        })
        
        print("📋 Server favorite ids: \(serverFavoriteIds)")
        print("📋 Local recipe ids: \(recipes.map { $0.remoteId })")
        
        var updatedCount = 0
        
        // Update local recipes to match server state - ensure this happens on main actor
        await MainActor.run {
            for recipe in recipes {
                let id = recipe.remoteId
                let shouldBeFavorite = serverFavoriteIds.contains(id)
                if recipe.isFavorite != shouldBeFavorite {
                    recipe.isFavorite = shouldBeFavorite
                    updatedCount += 1
                    print("🔄 Updated recipe '\(recipe.name ?? "Unknown")' favorite state to: \(shouldBeFavorite)")
                }
            }
        }
        
        print("✅ Synced Favourites: \(updatedCount) recipes updated")
    }
    
    enum ImageType: String, CaseIterable {
        case original = "original.webp"
        case minOriginal = "min-original.webp"
        case tinyOriginal = "tiny-original.webp"
    }
    
    // MARK: - Delete
    func deleteRecipe(slug: String) async throws {
        // DELETE /api/recipes/{recipe_slug}
        throw MealieAPIError.custom("Not implemented")
    }
    
    // MARK: - Transformation Layer
    // Implement JSON -> SwiftData model transformation here
} 
