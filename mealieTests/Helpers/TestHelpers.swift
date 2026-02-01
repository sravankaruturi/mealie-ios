import Foundation
import SwiftData
import Testing
@testable import mealIO

// MARK: - SwiftData Test Helper

/// Creates a fresh in-memory SwiftData `ModelContext` for test isolation.
func makeTestModelContext() -> ModelContext {
    let schema = Schema([
        Recipe.self, Ingredient.self, Instruction.self,
        MealPlanEntry.self, User.self, Tag.self,
        RecipeCategory.self, RecipeTool.self,
        RecipeNutrition.self, RecipeSettings.self,
        RecipeAsset.self, RecipeNote.self, RecipeComment.self
    ])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    return ModelContext(container)
}

// MARK: - Sample Data Factories

/// Creates a test recipe with sensible defaults.
func makeTestRecipe(
    name: String = "Test Recipe",
    slug: String = "test-recipe",
    remoteId: String? = nil,
    userId: String = "user-1",
    groupId: String = "group-1",
    houseHoldId: String = "household-1",
    isFavorite: Bool = false,
    ingredients: [Ingredient] = [],
    instructions: [Instruction] = []
) -> Recipe {
    return Recipe(
        remoteId: remoteId ?? UUID().uuidString,
        userId: userId,
        groupId: groupId,
        houseHoldId: houseHoldId,
        name: name,
        slug: slug,
        image: nil,
        recipeDescription: "Test description",
        recipeServings: 4,
        recipeYieldQuantity: 4,
        recipeYield: "4 servings",
        totalTime: nil,
        prepTime: nil,
        cookTime: nil,
        performTime: nil,
        rating: nil,
        orgUrl: nil,
        dateAdded: nil,
        dateUpdated: nil,
        createdAt: nil,
        lastMade: nil,
        update_at: nil,
        isFavorite: isFavorite,
        ingredients: ingredients,
        instructions: instructions
    )
}

/// Returns a test user with standard sample data.
func makeTestUser() -> User {
    return User.sampleData
}
