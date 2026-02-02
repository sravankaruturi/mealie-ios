import XCTest
import SnapshotTesting
import SwiftUI
import SwiftData
@testable import mealIO

@MainActor
final class RecipeDetailViewSnapshotTests: XCTestCase {

    func test_fullRecipe() {
        let apiService = TestAPIService()

        let ingredients = [
            Ingredient(orderIndex: 0, name: "Spaghetti", quantity: 400, unit: IngredientUnit(name: "Grams"), originalText: "400 Grams Spaghetti", note: ""),
            Ingredient(orderIndex: 1, name: "Eggs", quantity: 4, unit: IngredientUnit(name: "Item"), originalText: "4 Eggs", note: "large"),
            Ingredient(orderIndex: 2, name: "Parmesan", quantity: 100, unit: IngredientUnit(name: "Grams"), originalText: "100 Grams Parmesan", note: "freshly grated"),
        ]
        let instructions = [
            Instruction(step: 1, text: "Bring a large pot of salted water to boil. Cook spaghetti according to package directions."),
            Instruction(step: 2, text: "Meanwhile, whisk eggs and parmesan together in a bowl."),
            Instruction(step: 3, text: "Drain pasta, reserving 1 cup pasta water. Toss hot pasta with egg mixture."),
        ]

        let recipe = makeTestRecipe(
            name: "Spaghetti Carbonara",
            slug: "spaghetti-carbonara",
            ingredients: ingredients,
            instructions: instructions
        )
        recipe.prepTime = "10 min"
        recipe.performTime = "20 min"
        recipe.recipeServings = 4

        let view = snapshotView(
            NavigationStack {
                RecipeDetailView(recipe: recipe, mealieAPIService: apiService)
            },
            authStatus: .authenticated(makeTestUser())
        )
        assertViewSnapshot(view)
    }

    func test_minimalRecipe() {
        let apiService = TestAPIService()
        let recipe = makeTestRecipe(name: "Quick Snack", slug: "quick-snack")

        let view = snapshotView(
            NavigationStack {
                RecipeDetailView(recipe: recipe, mealieAPIService: apiService)
            },
            authStatus: .authenticated(makeTestUser())
        )
        assertViewSnapshot(view)
    }

    func test_recipeWithSections() {
        let apiService = TestAPIService()

        let ingredients = [
            Ingredient(orderIndex: 0, name: "Pasta", quantity: 500, unit: IngredientUnit(name: "Grams"), originalText: "500 Grams Pasta", note: "", title: "For the pasta"),
            Ingredient(orderIndex: 1, name: "Olive Oil", quantity: 2, unit: IngredientUnit(name: "Tablespoon"), originalText: "2 Tablespoon Olive Oil", note: ""),
            Ingredient(orderIndex: 2, name: "Tomatoes", quantity: 400, unit: IngredientUnit(name: "Grams"), originalText: "400 Grams Tomatoes", note: "canned", title: "For the sauce"),
            Ingredient(orderIndex: 3, name: "Garlic", quantity: 3, unit: IngredientUnit(name: "Clove"), originalText: "3 Clove Garlic", note: "minced"),
        ]
        let instructions = [
            Instruction(step: 1, text: "Cook pasta in salted boiling water.", title: "Prepare pasta"),
            Instruction(step: 2, text: "Heat olive oil in a large pan over medium heat.", title: "Make the sauce"),
            Instruction(step: 3, text: "Add garlic and tomatoes. Simmer for 15 minutes."),
        ]

        let recipe = makeTestRecipe(
            name: "Pasta al Pomodoro",
            slug: "pasta-al-pomodoro",
            ingredients: ingredients,
            instructions: instructions
        )

        let view = snapshotView(
            NavigationStack {
                RecipeDetailView(recipe: recipe, mealieAPIService: apiService)
            },
            authStatus: .authenticated(makeTestUser())
        )
        assertViewSnapshot(view)
    }
}
