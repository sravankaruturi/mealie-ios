import XCTest
import SnapshotTesting
import SwiftUI
import SwiftData
@testable import mealIO

@MainActor
final class EditRecipeViewSnapshotTests: XCTestCase {

    func test_newRecipe() {
        let apiService = TestAPIService()
        let ctx = makeTestModelContext()
        let user = makeTestUser()
        let recipe = Recipe()

        let view = snapshotView(
            EditRecipeBodyView(
                recipe: recipe,
                modelContext: ctx,
                mealieAPIService: apiService,
                user: user,
                isNewRecipe: true
            ),
            authStatus: .authenticated(user),
            modelContext: ctx
        )
        assertViewSnapshot(view)
    }

    func test_existingRecipe() {
        let apiService = TestAPIService()
        let ctx = makeTestModelContext()
        let user = makeTestUser()

        let ingredients = [
            Ingredient(orderIndex: 0, name: "Flour", quantity: 2, unit: IngredientUnit(name: "cups"), originalText: "2 cups flour", note: ""),
            Ingredient(orderIndex: 1, name: "Sugar", quantity: 1, unit: IngredientUnit(name: "cup"), originalText: "1 cup sugar", note: ""),
        ]
        let instructions = [
            Instruction(step: 1, text: "Mix flour and sugar together in a large bowl."),
            Instruction(step: 2, text: "Bake at 350 degrees for 30 minutes."),
        ]

        let recipe = makeTestRecipe(
            name: "Vanilla Cake",
            slug: "vanilla-cake",
            ingredients: ingredients,
            instructions: instructions
        )
        recipe.orgUrl = "https://recipes.example.com/vanilla-cake"

        let view = snapshotView(
            EditRecipeBodyView(
                recipe: recipe,
                modelContext: ctx,
                mealieAPIService: apiService,
                user: user,
                isNewRecipe: false
            ),
            authStatus: .authenticated(user),
            modelContext: ctx
        )
        assertViewSnapshot(view)
    }

    func test_recipeWithManyIngredients() {
        let apiService = TestAPIService()
        let ctx = makeTestModelContext()
        let user = makeTestUser()

        let ingredients = (0..<6).map { i in
            Ingredient(
                orderIndex: i,
                name: "Ingredient \(i + 1)",
                quantity: Double(i + 1),
                unit: IngredientUnit(name: "cups"),
                originalText: "\(i + 1) cups Ingredient \(i + 1)",
                note: ""
            )
        }
        let instructions = (1...4).map { step in
            Instruction(step: step, text: "Step \(step): Do something important for the recipe.")
        }

        let recipe = makeTestRecipe(
            name: "Complex Recipe",
            slug: "complex-recipe",
            ingredients: ingredients,
            instructions: instructions
        )

        let view = snapshotView(
            EditRecipeBodyView(
                recipe: recipe,
                modelContext: ctx,
                mealieAPIService: apiService,
                user: user,
                isNewRecipe: false
            ),
            authStatus: .authenticated(user),
            modelContext: ctx
        )
        assertViewSnapshot(view)
    }
}
