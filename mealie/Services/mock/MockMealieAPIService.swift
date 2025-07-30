//
//  MockMealieAPIService.swift
//  mealie
//
//  Created by Sravan Karuturi on 7/26/25.
//

import Foundation
import OpenAPIRuntime

final class MockMealieAPIService: MealieAPIServiceProtocol {
    
    // MARK: - Mock Data
    private var mockRecipes: [Recipe] = []
    private var mockFavorites: Set<String> = []
    private var mockUser: Components.Schemas.UserOut?
    private var mockServerURL: URL?
    
    // MARK: - Configuration
    func setURL(_ url: URL) {
        mockServerURL = url
    }
    
    // MARK: - Authentication
    func login(username: String, password: String) async throws -> String {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        if username == "test" && password == "test" {
            return "mock-jwt-token-12345"
        } else {
            throw MealieAPIError.unauthorized
        }
    }
    
    // MARK: - Recipes
    func fetchAllRecipes(page: Int, perPage: Int) async throws -> [Recipe] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        if mockRecipes.isEmpty {
            mockRecipes = createMockRecipes()
        }
        
        return mockRecipes
    }
    
    func fetchAllRecipesOptimized(existingRecipes: [Recipe], page: Int, perPage: Int) async throws -> [Recipe] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        if mockRecipes.isEmpty {
            mockRecipes = createMockRecipes()
        }
        
        // Simulate some recipes being updated
        var updatedRecipes = existingRecipes
        for (index, recipe) in updatedRecipes.enumerated() {
            if index % 3 == 0 { // Update every 3rd recipe
                recipe.dateUpdated = ISO8601DateFormatter().string(from: Date())
            }
        }
        
        return updatedRecipes
    }
    
    func fetchRecipeDetails(slug: String) async throws -> Recipe {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        if let existingRecipe = mockRecipes.first(where: { $0.slug == slug }) {
            return existingRecipe
        }
        
        // Create a new mock recipe if not found
        let newRecipe = createMockRecipe(slug: slug)
        mockRecipes.append(newRecipe)
        return newRecipe
    }
    
    func addRecipeManual(recipeData: [String: Any]) async throws -> Recipe {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let newRecipe = createMockRecipe(slug: "manual-recipe-\(UUID().uuidString)")
        mockRecipes.append(newRecipe)
        return newRecipe
    }
    
    func parseRecipeURL(url: URL) async throws -> String {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        return "parsed-recipe-\(UUID().uuidString)"
    }
    
    func addRecipeFromURL(url: URL) async throws -> Recipe {
        let slug = try await parseRecipeURL(url: url)
        return try await fetchRecipeDetails(slug: slug)
    }
    
    func updateRecipe(slug: String, recipeData: Components.Schemas.Recipe_hyphen_Input) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        if let index = mockRecipes.firstIndex(where: { $0.slug == slug }) {
            // Update the existing recipe
            let updatedRecipe = createMockRecipe(slug: slug)
            updatedRecipe.dateUpdated = ISO8601DateFormatter().string(from: Date())
            mockRecipes[index] = updatedRecipe
        } else {
            throw MealieAPIError.custom("Recipe not found")
        }
    }
    
    func deleteRecipe(slug: String) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        mockRecipes.removeAll { $0.slug == slug }
    }
    
    // MARK: - Meal Plan
    func createMealPlanEntry(entryData: [String: Any]) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Mock implementation - just succeed
    }
    
    // MARK: - Images
    func getRecipeImageURL(recipeId: String, imageType: ImageType) -> URL? {
        return URL(string: "https://picsum.photos/id/63/200/300")
    }
    
    func getRecipeImageURLForKingfisher(recipeId: String, imageType: ImageType) -> URL? {
        return getRecipeImageURL(recipeId: recipeId, imageType: imageType)
    }
    
    // MARK: - Favorites
    func getCurrentUser() async throws -> Components.Schemas.UserOut {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        if let user = mockUser {
            return user
        }
        
        mockUser = Components.Schemas.UserOut(
        id: "1", email: "test@testing.com", group: "1", household: "2", groupId: "Group ID", groupSlug: "Group Slug", householdId: "Household ID", householdSlug: "Household Slug", cacheKey: "CacheKey")
        
        return mockUser!
    }
    
    func addToFavorites(recipeSlug: String) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        mockFavorites.insert(recipeSlug)
    }
    
    func removeFromFavorites(recipeSlug: String) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        mockFavorites.remove(recipeSlug)
    }
    
    func getCurrentUserFavorites() async throws -> Components.Schemas.UserRatings_UserRatingSummary_ {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let ratings = mockFavorites.map { slug in
            Components.Schemas.UserRatingSummary(
                recipeId: slug,
                rating: 5,
                isFavorite: true
            )
        }
        
        return Components.Schemas.UserRatings_UserRatingSummary_(
            ratings: ratings
        )
    }
    
    func syncFavoritesFromServer(recipes: [Recipe]) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        await MainActor.run {
            for recipe in recipes {
                recipe.isFavorite = mockFavorites.contains(recipe.slug)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func createMockRecipes() -> [Recipe] {
        return [
            createMockRecipe(slug: "spaghetti-carbonara", name: "Spaghetti Carbonara"),
            createMockRecipe(slug: "chicken-curry", name: "Chicken Curry"),
            createMockRecipe(slug: "chocolate-cake", name: "Chocolate Cake"),
            createMockRecipe(slug: "caesar-salad", name: "Caesar Salad"),
            createMockRecipe(slug: "beef-stew", name: "Beef Stew")
        ]
    }
    
    private func createMockRecipe(slug: String, name: String? = nil) -> Recipe {
        let recipeName = name ?? "Mock Recipe \(slug.prefix(10))"
        
        let recipe = Recipe(
            remoteId: slug,
            userId: "mock-user-id",
            groupId: "mock-group-id",
            houseHoldId: "mock-household-id",
            name: recipeName,
            slug: slug,
            image: "mock-image-\(slug).jpg",
            recipeDescription: "A delicious mock recipe for testing purposes",
            recipeServings: 4,
            recipeYieldQuantity: 4,
            recipeYield: "4 servings",
            totalTime: "45 minutes",
            prepTime: "15 minutes",
            cookTime: "30 minutes",
            performTime: nil,
            rating: 4,
            orgUrl: "https://example.com/recipe/\(slug)",
            dateAdded: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 7)), // 7 days ago
            dateUpdated: ISO8601DateFormatter().string(from: Date()),
            createdAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 30)), // 30 days ago
            lastMade: nil,
            update_at: nil,
            lastModified: Date(),
            isFavorite: mockFavorites.contains(slug)
        )
        
        // Add some mock ingredients
        recipe.ingredients = [
            Ingredient(
                orderIndex: 0,
                name: "Mock Ingredient 1",
                quantity: 1.0,
                unit: .matchUnit("tbsp"),
                originalText: "Original Text",
                note: "Mock ingredient",
                title: "Ingredient 1",
                recipe: recipe,
            ),
            
            Ingredient(
                orderIndex: 1,
                name: "Mock Ingredient 2",
                quantity: 2.0,
                unit: .matchUnit("tbsp"),
                originalText: "Original Text",
                note: "Mock ingredient",
                title: "Ingredient 2",
                recipe: recipe,
            ),
        ]
        
        // Add some mock instructions
        recipe.instructions = [
            Instruction(
                id: UUID().uuidString,
                step: 1,
                text: "Step 1: Prepare the ingredients",
                title: nil,
                recipe: recipe,
            ),
            Instruction(
                id: UUID().uuidString,
                step: 2,
                text: "Step 2: Prepare the ingredients",
                title: "Test Title",
                recipe: recipe,
            ),
            Instruction(
                id: UUID().uuidString,
                step: 3,
                text: "Step 3: Prepare the ingredients",
                title: nil,
                recipe: recipe,
            )
        ]
        
        return recipe
    }
    
    // MARK: - Mock Data Manipulation
    func setMockFavorites(_ favorites: Set<String>) {
        mockFavorites = favorites
    }
    
    func addMockRecipe(_ recipe: Recipe) {
        mockRecipes.append(recipe)
    }
    
    func clearMockData() {
        mockRecipes.removeAll()
        mockFavorites.removeAll()
        mockUser = nil
    }
    
    static let sampleRecipe = Recipe(
        remoteId: "sample-recipe-123",
        userId: "user-123",
        groupId: "group-123",
        houseHoldId: "household-123",
        name: "Delicious Spaghetti Carbonara",
        slug: "delicious-spaghetti-carbonara",
        image: "sample-image-url",
        recipeDescription: "A classic Italian pasta dish with eggs, cheese, pancetta, and black pepper. This creamy and flavorful recipe is perfect for a quick weeknight dinner.",
        recipeServings: 4,
        recipeYieldQuantity: 4,
        recipeYield: "4 servings",
        totalTime: "30 minutes",
        prepTime: "10 minutes",
        cookTime: "20 minutes",
        performTime: nil,
        rating: 5,
        orgUrl: "https://example.com/recipe",
        dateAdded: "2024-01-15",
        dateUpdated: "2024-01-15",
        createdAt: "2024-01-15",
        lastMade: nil,
        update_at: "2024-01-15",
        lastModified: Date(),
        isFavorite: false
    )
    
    static let favoriteRecipe = Recipe(
        remoteId: "favorite-recipe-456",
        userId: "user-123",
        groupId: "group-123",
        houseHoldId: "household-123",
        name: "Chocolate Chip Cookies",
        slug: "chocolate-chip-cookies",
        image: "favorite-image-url",
        recipeDescription: "Soft and chewy chocolate chip cookies with a golden brown exterior and gooey chocolate chips throughout.",
        recipeServings: 24,
        recipeYieldQuantity: 24,
        recipeYield: "24 cookies",
        totalTime: "45 minutes",
        prepTime: "15 minutes",
        cookTime: "12 minutes",
        performTime: nil,
        rating: 5,
        orgUrl: "https://example.com/cookies",
        dateAdded: "2024-01-10",
        dateUpdated: "2024-01-10",
        createdAt: "2024-01-10",
        lastMade: nil,
        update_at: "2024-01-10",
        lastModified: Date(),
        isFavorite: true
    )
    
    static let thirdRecipe = Recipe(
        remoteId: "third-recipe-789",
        userId: "user-123",
        groupId: "group-123",
        houseHoldId: "household-123",
        name: "Grilled Chicken Salad",
        slug: "grilled-chicken-salad",
        image: "https://demo.mealie.io/api/media/recipes/7e099149-4f76-449d-86c6-1e5d65e4e543/images/original.webp",
        recipeDescription: "Fresh mixed greens with grilled chicken breast, cherry tomatoes, cucumber, and a light vinaigrette dressing.",
        recipeServings: 2,
        recipeYieldQuantity: 2,
        recipeYield: "2 servings",
        totalTime: "25 minutes",
        prepTime: "15 minutes",
        cookTime: "10 minutes",
        performTime: nil,
        rating: 4,
        orgUrl: "https://example.com/salad",
        dateAdded: "2024-01-20",
        dateUpdated: "2024-01-20",
        createdAt: "2024-01-20",
        lastMade: nil,
        update_at: "2024-01-20",
        lastModified: Date(),
        isFavorite: false
    )
    
    static let fourthRecipe = Recipe(
        remoteId: "fourth-recipe-124",
        userId: "user-123",
        groupId: "group-123",
        houseHoldId: "household-123",
        name: "Delicious Spaghetti Carbonara",
        slug: "delicious-spaghetti-carbonara",
        image: "sample-image-url",
        recipeDescription: "A classic Italian pasta dish with eggs, cheese, pancetta, and black pepper. This creamy and flavorful recipe is perfect for a quick weeknight dinner.",
        recipeServings: 4,
        recipeYieldQuantity: 4,
        recipeYield: "4 servings",
        totalTime: "30 minutes",
        prepTime: "10 minutes",
        cookTime: "20 minutes",
        performTime: nil,
        rating: 5,
        orgUrl: "https://example.com/recipe",
        dateAdded: "2024-01-15",
        dateUpdated: "2024-01-15",
        createdAt: "2024-01-15",
        lastMade: nil,
        update_at: "2024-01-15",
        lastModified: Date(),
        isFavorite: false
    )
    
    static let fifthRecipe = Recipe(
        remoteId: "fifth-recipe-125",
        userId: "user-123",
        groupId: "group-123",
        houseHoldId: "household-123",
        name: "Delicious Spaghetti Carbonara",
        slug: "delicious-spaghetti-carbonara",
        image: "sample-image-url",
        recipeDescription: "A classic Italian pasta dish with eggs, cheese, pancetta, and black pepper. This creamy and flavorful recipe is perfect for a quick weeknight dinner.",
        recipeServings: 4,
        recipeYieldQuantity: 4,
        recipeYield: "4 servings",
        totalTime: "30 minutes",
        prepTime: "10 minutes",
        cookTime: "20 minutes",
        performTime: nil,
        rating: 5,
        orgUrl: "https://example.com/recipe",
        dateAdded: "2024-01-15",
        dateUpdated: "2024-01-15",
        createdAt: "2024-01-15",
        lastMade: nil,
        update_at: "2024-01-15",
        lastModified: Date(),
        isFavorite: false
    )
    
    static let sixthRecipe = Recipe(
        remoteId: "sixth-recipe-126",
        userId: "user-123",
        groupId: "group-123",
        houseHoldId: "household-123",
        name: "Delicious Spaghetti Carbonara",
        slug: "delicious-spaghetti-carbonara",
        image: "sample-image-url",
        recipeDescription: "A classic Italian pasta dish with eggs, cheese, pancetta, and black pepper. This creamy and flavorful recipe is perfect for a quick weeknight dinner.",
        recipeServings: 4,
        recipeYieldQuantity: 4,
        recipeYield: "4 servings",
        totalTime: "30 minutes",
        prepTime: "10 minutes",
        cookTime: "20 minutes",
        performTime: nil,
        rating: 5,
        orgUrl: "https://example.com/recipe",
        dateAdded: "2024-01-15",
        dateUpdated: "2024-01-15",
        createdAt: "2024-01-15",
        lastMade: nil,
        update_at: "2024-01-15",
        lastModified: Date(),
        isFavorite: false
    )
    
    static let seventhRecipe = Recipe(
        remoteId: "seventh-recipe-127",
        userId: "user-123",
        groupId: "group-123",
        houseHoldId: "household-123",
        name: "Delicious Spaghetti Carbonara",
        slug: "delicious-spaghetti-carbonara",
        image: "sample-image-url",
        recipeDescription: "A classic Italian pasta dish with eggs, cheese, pancetta, and black pepper. This creamy and flavorful recipe is perfect for a quick weeknight dinner.",
        recipeServings: 4,
        recipeYieldQuantity: 4,
        recipeYield: "4 servings",
        totalTime: "30 minutes",
        prepTime: "10 minutes",
        cookTime: "20 minutes",
        performTime: nil,
        rating: 5,
        orgUrl: "https://example.com/recipe",
        dateAdded: "2024-01-15",
        dateUpdated: "2024-01-15",
        createdAt: "2024-01-15",
        lastMade: nil,
        update_at: "2024-01-15",
        lastModified: Date(),
        isFavorite: false
    )
    
    
    static let eightRecipe = Recipe(
        remoteId: "eight-recipe-128",
        userId: "user-123",
        groupId: "group-123",
        houseHoldId: "household-123",
        name: "Delicious Spaghetti Carbonara",
        slug: "delicious-spaghetti-carbonara",
        image: "sample-image-url",
        recipeDescription: "A classic Italian pasta dish with eggs, cheese, pancetta, and black pepper. This creamy and flavorful recipe is perfect for a quick weeknight dinner.",
        recipeServings: 4,
        recipeYieldQuantity: 4,
        recipeYield: "4 servings",
        totalTime: "30 minutes",
        prepTime: "10 minutes",
        cookTime: "20 minutes",
        performTime: nil,
        rating: 5,
        orgUrl: "https://example.com/recipe",
        dateAdded: "2024-01-15",
        dateUpdated: "2024-01-15",
        createdAt: "2024-01-15",
        lastMade: nil,
        update_at: "2024-01-15",
        lastModified: Date(),
        isFavorite: false
    )
    
}
