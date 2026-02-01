import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

/// Concrete Mealie API client using OpenAPI-generated transport.
final class MealieAPIService: MealieAPIServiceProtocol {
    
    private(set) var serverURL: URL?
    private var session: URLSession
    
    private let authMiddleware = AuthenticationMiddleware()
    
    var client: Client?
    
    /// Creates the API service, optionally connecting to the given server URL.
    /// - Parameter serverURL: The initial server URL, or `nil` to configure later.
    init(serverURL: URL?) {

        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)

        if let url = serverURL {
            setURL(url)
        }

    }
    
    /// Reconfigures the HTTP client with a new server URL and authentication middleware.
    /// - Parameter url: The new base URL for the Mealie server.
    public func setURL(_ url: URL) {
        self.serverURL = url
        self.client = Client(
            serverURL: url,
            transport: URLSessionTransport(),
            middlewares: [self.authMiddleware]
        )
    }
    
    // MARK: - Authentication
    /// Authenticates with username/password and stores the token in Keychain.
    /// - Parameters:
    ///   - username: The user's login name.
    ///   - password: The user's password.
    /// - Returns: The access token string.
    /// - Throws: `MealieAPIError` on failure (unauthorized, network, decoding).
    func login(username: String, password: String) async throws -> String {
        
        let requestBody = Components.Schemas.Body_get_token_api_auth_token_post(
            username: username,
            password: password,
            remember_me: true
        )
        
        let input = Operations.get_token_api_auth_token_post.Input(
            body: .urlEncodedForm(requestBody)
            )
        
        guard let client = client else {
            throw MealieAPIError.custom("Client not initialized. Please set server URL first.")
        }

        guard let serverURL = serverURL else {
            throw MealieAPIError.invalidURL
        }

        do {
            let output = try await client.get_token_api_auth_token_post(input)

            switch output {

            case .ok(let response):
                let jsonResponse = try response.body.json

                guard let token = jsonResponse.access_token else {
                    throw MealieAPIError.custom("No access_token in response.")
                }

                let savedToKeyChain = KeychainService.shared.saveToken(token, serverURL: serverURL)
                if !savedToKeyChain {
                    AppLogger.warning("Unable to Save Token to Keychain")
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
            AppLogger.error(.network, "URLError occurred: \(error)")
            AppLogger.debug(.network, "URLError code: \(error.code)")
            if error.code == .appTransportSecurityRequiresSecureConnection || error.code == .serverCertificateUntrusted {
                throw MealieAPIError.insecureConnection
            }
            throw MealieAPIError.networkError(error)
        } catch let error as DecodingError {
            AppLogger.error(.network, "DecodingError occurred: \(error)")
            throw MealieAPIError.decodingError(error)
        } catch {
            AppLogger.error(.network, "Unknown error occurred: \(error)")
            AppLogger.debug(.network, "Error type: \(type(of: error))")
            // Catches decoding errors or other issues.
            throw MealieAPIError.networkError(error)
        }
    
    }
    
    /// Fetches user details and converts to the local `User` model.
    /// - Returns: A `User` representing the authenticated user.
    func fetchUserDetails() async throws -> User {
        
        let userDetails = try await getCurrentUser()
        return User(from: userDetails)
        
    }
    
    // MARK: - Recipes

    /// Fetches all recipes with full details - makes N+1 API calls (1 for list + N for details).
    /// - Note: Prefer `fetchAllRecipesOptimized(existingRecipes:)` which only fetches changed recipes.
    /// - Parameters:
    ///   - page: The page number to fetch (default 1).
    ///   - perPage: The number of recipes per page (default 50).
    /// - Returns: An array of fully-detailed `Recipe` objects.
    @available(*, deprecated, message: "Use fetchAllRecipesOptimized(existingRecipes:) instead to avoid N+1 query problem")
    func fetchAllRecipes(page: Int = 1, perPage: Int = 50) async throws -> [Recipe] {
        // Delegate to optimized version with empty array (fetches all as "new")
        return try await fetchAllRecipesOptimized(existingRecipes: [], page: page, perPage: perPage)
    }
    
    /// Smart sync: only downloads details for new or updated recipes.
    /// - Parameters:
    ///   - existingRecipes: Locally cached recipes to compare timestamps against.
    ///   - page: The page number to fetch (default 1).
    ///   - perPage: The number of recipes per page (default 50).
    /// - Returns: An array of `Recipe` objects with only changed ones re-fetched from the server.
    func fetchAllRecipesOptimized(existingRecipes: [Recipe], page: Int = 1, perPage: Int = 50) async throws -> [Recipe] {

        guard let client = client else {
            throw MealieAPIError.custom("Client not initialized. Please set server URL first.")
        }

        let input = Operations.get_all_api_recipes_get.Input(query: .init(page: page, perPage: perPage))
        let output = try await client.get_all_api_recipes_get(input)
        
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
                        AppLogger.debug(.sync, "Fetching updated recipe: \(existingRecipe.name ?? "Unknown") (server: \(recipeSummary.dateUpdated ?? "nil"), local: \(existingRecipe.dateUpdated ?? "nil"))")
                        let updatedRecipe = try await fetchRecipeDetails(slug: slug)
                        // Preserve favorite state
                        updatedRecipe.isFavorite = existingRecipe.isFavorite
                        updatedRecipes.append(updatedRecipe)
                        fetchedCount += 1
                    }
                } else {
                    // New recipe, fetch full details
                    AppLogger.debug(.sync, "Fetching new recipe: \(recipeSummary.name ?? "Unknown")")
                    let newRecipe = try await fetchRecipeDetails(slug: slug)
                    updatedRecipes.append(newRecipe)
                    newCount += 1
                }
            }
            
            AppLogger.info(.sync, "Recipe sync stats: \(cachedCount) cached, \(fetchedCount) updated, \(newCount) new")
            
            return updatedRecipes
            
        default:
            throw MealieAPIError.custom("Failed to fetch recipes.")
        }
    }

    /// Fetches full recipe details for a single recipe by slug.
    /// - Parameter slug: The recipe's URL slug identifier.
    /// - Returns: A fully-detailed `Recipe` object.
    func fetchRecipeDetails(slug: String) async throws -> Recipe {
        // GET /api/recipes/{recipe_slug}
        guard let client = client else {
            throw MealieAPIError.custom("Client not initialized. Please set server URL first.")
        }

        let input = Operations.get_one_api_recipes__slug__get.Input(path: .init(slug: slug))
        let output = try await client.get_one_api_recipes__slug__get(input)
        
        switch output {
        case .ok(let response):
            
            let data: Components.Schemas.Recipe_hyphen_Output = try response.body.json
            
            let recipe = Recipe(output: data)
            
            return recipe
            
        default:
            throw MealieAPIError.custom("Failed to fetch recipe details.")
        }
    }
    
    /// Creates a blank recipe with the given name, returns its slug.
    /// - Parameter recipeName: The name for the new recipe.
    /// - Returns: The generated slug of the newly created recipe.
    func addRecipeManual(recipeName: String) async throws -> String {

        // POST /api/recipes
        guard let client = client else {
            throw MealieAPIError.custom("Client not initialized")
        }
        
        let createRecipeInput = Components.Schemas.CreateRecipe(name: recipeName)
        let body : Operations.create_one_api_recipes_post.Input.Body = .json(createRecipeInput)
        
        let input = Operations.create_one_api_recipes_post.Input(body: body)
        let output = try await client.create_one_api_recipes_post(input)

        switch output {
        case .created(let response):
            return try response.body.json
        case .unprocessableContent(let response):
            throw MealieAPIError.custom("Validation Error: \(response)")
        default:
            throw MealieAPIError.custom("Failed to add recipe.")
        }
        
    }
    
    /// Sends a URL to the server for scraping, returns the generated slug.
    /// - Parameter url: The recipe URL to scrape.
    /// - Returns: The slug of the newly created recipe.
    func parseRecipeURL(url: URL) async throws -> String {
        // POST /api/recipes/create/url
        guard let client = client else {
            throw MealieAPIError.custom("Client not initialized")
        }
        
        let requestBody = Components.Schemas.ScrapeRecipe(url: url.absoluteString)
        let input = Operations.parse_recipe_url_api_recipes_create_url_post.Input(body: .json(requestBody))
        
        let output = try await client.parse_recipe_url_api_recipes_create_url_post(input)
        
        switch output {
        case .created(let response):
            // The response body should contain the recipe slug as a string
            return try response.body.json
        case .unprocessableContent(let response):
            throw MealieAPIError.custom("Validation Error: \(response)")
        case .undocumented(let statusCode, _):
            if statusCode == 401 {
                throw MealieAPIError.unauthorized
            } else {
                throw MealieAPIError.networkError(NSError(domain: "HTTP error", code: statusCode))
            }
        }
    }
    
    /// Scrapes a recipe URL and returns the full Recipe object.
    /// - Parameter url: The recipe URL to scrape.
    /// - Returns: The complete `Recipe` object fetched after scraping.
    func addRecipeFromURL(url: URL) async throws -> Recipe {
        // First parse the URL to get the recipe slug
        let recipeSlug = try await parseRecipeURL(url: url)
        
        // Then fetch the recipe details using the slug
        let recipe = try await fetchRecipeDetails(slug: recipeSlug)
        
        return recipe
    }
    
    /// Pushes updated recipe data to the server via PUT.
    /// - Parameters:
    ///   - slug: The recipe's URL slug identifier.
    ///   - recipeData: The full recipe input payload to send.
    func updateRecipe(slug: String, recipeData: Components.Schemas.Recipe_hyphen_Input) async throws {
        // PUT /api/recipes/{slug}
        guard let client = client else {
            throw MealieAPIError.custom("Client not initialized")
        }
        
        AppLogger.debug(.network, "Updating recipe with slug: \(slug)")
        AppLogger.debug(.network, "Recipe data - ID: \(recipeData.id ?? "nil"), name: \(recipeData.name ?? "nil")")
        AppLogger.debug(.network, "Recipe data - userId: \(recipeData.userId), householdId: \(recipeData.householdId), groupId: \(recipeData.groupId)")
        AppLogger.debug(.network, "Recipe data - ingredients: \(recipeData.recipeIngredient?.count ?? 0), instructions: \(recipeData.recipeInstructions?.count ?? 0)")

        // Log request metadata for debugging (avoid logging full payload to prevent PII leakage)
        do {
            let jsonData = try JSONEncoder().encode(recipeData)
            AppLogger.debug(.network, "Request body size: \(jsonData.count) bytes")
        } catch {
            AppLogger.warning(.network, "Could not encode request body for logging: \(error)")
        }
        
        let input = Operations.update_one_api_recipes__slug__put.Input(
            path: .init(slug: slug),
            body: .json(recipeData)
        )
        
        AppLogger.debug(.network, "Making API request to update recipe...")

        let output = try await client.update_one_api_recipes__slug__put(input)

        AppLogger.debug(.network, "Received response for recipe update")

        switch output {
        case .ok:
            AppLogger.info(.network, "Recipe updated successfully")
            // Successfully updated
            break
        case .unprocessableContent(let response):
            AppLogger.error(.network, "Validation error (unprocessable content)")
            AppLogger.debug(.network, "Validation details: \(response)")
            throw MealieAPIError.custom("Validation Error: \(response)")
        case .undocumented(let statusCode, let response):
            AppLogger.error(.network, "Undocumented status code: \(statusCode)")
            AppLogger.debug(.network, "Response: \(response)")

            // Try to extract error message from response body
            if let responseBody = response.body {
                do {
                    let data = try await responseBody.reduce(into: Data()) { $0.append(contentsOf: $1) }
                    AppLogger.debug(.network, "Response body size: \(data.count) bytes")
                } catch {
                    AppLogger.warning(.network, "Could not read response body: \(error)")
                }
            }
            
            if statusCode == 401 {
                throw MealieAPIError.unauthorized
            } else if statusCode == 500 {
                throw MealieAPIError.custom("Server error (500): Internal server error occurred")
            } else {
                throw MealieAPIError.networkError(NSError(domain: "HTTP error", code: statusCode))
            }
        }
    }
    
    // MARK: - Meal Plan
    /// Creates a meal plan entry (not yet implemented).
    /// - Parameter entryData: Dictionary containing the meal plan entry fields.
    func createMealPlanEntry(entryData: [String: Any]) async throws {
        // POST /api/meal-plans
        throw MealieAPIError.custom("Not implemented")
    }
    
    // MARK: - Images
    /// Builds the media URL for a recipe image.
    /// - Parameters:
    ///   - recipeId: The recipe's unique identifier.
    ///   - imageType: The desired image size variant (default `.original`).
    /// - Returns: The fully-qualified image URL, or `nil` if the server URL is not set.
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
    /// Convenience wrapper for Kingfisher image loading.
    /// - Parameters:
    ///   - recipeId: The recipe's unique identifier.
    ///   - imageType: The desired image size variant (default `.original`).
    /// - Returns: The image URL suitable for Kingfisher, or `nil` if unavailable.
    func getRecipeImageURLForKingfisher(recipeId: String, imageType: ImageType = .original) -> URL? {
        return getRecipeImageURL(recipeId: recipeId, imageType: imageType)
    }
    
    // MARK: - Favorites
    /// Fetches the logged-in user's profile via GET /api/users/self.
    /// - Returns: The raw `UserOut` schema from the server.
    func getCurrentUser() async throws -> Components.Schemas.UserOut {
        guard let client = client else {
            throw MealieAPIError.custom("Client not initialized")
        }
        
        let input = Operations.get_logged_in_user_api_users_self_get.Input(
            headers: .init()
        )
        
        let output = try await client.get_logged_in_user_api_users_self_get(input)
        
        switch output {
        case .ok(let response):
            return try response.body.json
        default:
            throw MealieAPIError.custom("Failed to get current user")
        }
    }
    
    /// Adds a recipe to the current user's favorites.
    /// - Parameter recipeSlug: The slug of the recipe to favorite.
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
    
    /// Removes a recipe from the current user's favorites.
    /// - Parameter recipeSlug: The slug of the recipe to unfavorite.
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
    
    /// Fetches the current user's favorites and ratings list.
    /// - Returns: The user's ratings/favorites summary from the server.
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
    
    /// Downloads favorite state from server and updates local Recipe models.
    /// - Parameter recipes: The local recipe models whose favorite flags will be updated.
    func syncFavoritesFromServer(recipes: [Recipe]) async throws {
        AppLogger.debug(.sync, "Starting favorites sync...")
        let serverFavorites = try await getCurrentUserFavorites()

        AppLogger.debug(.sync, "Server favorites response: \(serverFavorites.ratings.count) ratings")

        // Debug: Log the structure of the first rating to understand the data
        if let firstRating = serverFavorites.ratings.first {
            AppLogger.debug(.sync, "First rating structure: \(firstRating)")
        }

        // Create a set of favorite recipe slugs from server
        let serverFavoriteIds = Set<String>(serverFavorites.ratings.compactMap { rating -> String? in

            guard let isFav = rating.isFavorite, isFav else {
                return nil
            }

            // Try different possible field names for the recipe identifier
            let recipeId = rating.recipeId
            AppLogger.debug(.sync, "Found favorite recipe: \(recipeId)")
            return recipeId
        })

        AppLogger.debug(.sync, "Server favorite ids: \(serverFavoriteIds)")
        AppLogger.debug(.sync, "Local recipe ids: \(recipes.map { $0.remoteId })")
        
        var updatedCount = 0
        
        // Update local recipes to match server state - ensure this happens on main actor
        await MainActor.run {
            for recipe in recipes {
                let id = recipe.remoteId
                let shouldBeFavorite = serverFavoriteIds.contains(id)
                if recipe.isFavorite != shouldBeFavorite {
                    recipe.isFavorite = shouldBeFavorite
                    updatedCount += 1
                    AppLogger.debug(.sync, "Updated recipe '\(recipe.name ?? "Unknown")' favorite state to: \(shouldBeFavorite)")
                }
            }
        }
        
        AppLogger.info(.sync, "Synced favourites: \(updatedCount) recipes updated")
    }
    

    
    // MARK: - Delete
    /// Deletes a recipe (not yet implemented).
    /// - Parameter slug: The recipe's URL slug identifier.
    func deleteRecipe(slug: String) async throws {
        // DELETE /api/recipes/{recipe_slug}
        throw MealieAPIError.custom("Not implemented")
    }
    
    /// Fetches all ingredient units in a single request.
    /// - Returns: An array of ingredient unit schemas.
    func fetchAllUnits() async throws -> [Components.Schemas.IngredientUnit_hyphen_Output] {
        guard let client = client else {
            throw MealieAPIError.custom("Client not initialized")
        }
        
        let input = Operations.get_all_api_units_get.Input(query: .init(perPage: -1))
        let output = try await client.get_all_api_units_get(input)
        
        switch output {
        case .ok(let response):
            let paginationResponse = try response.body.json
            return paginationResponse.items
        default:
            throw MealieAPIError.custom("Failed to fetch units")
        }
        
    }
    
    // MARK: - Foods
    /// Fetches all ingredient food items in a single request.
    /// - Returns: An array of ingredient food schemas.
    func fetchAllFoods() async throws -> [Components.Schemas.IngredientFood_hyphen_Output] {
        guard let client = client else {
            throw MealieAPIError.custom("Client not initialized")
        }

        // Use perPage: -1 to fetch all food items in a single request
        let input = Operations.get_all_api_foods_get.Input(query: .init(perPage: -1))
        let output = try await client.get_all_api_foods_get(input)

        switch output {
        case .ok(let response):
            let paginationResponse = try response.body.json
            return paginationResponse.items
        default:
            throw MealieAPIError.custom("Failed to fetch foods.")
        }
    }
    
    // MARK: - Transformation Layer
    // Implement JSON -> SwiftData model transformation here
} 
