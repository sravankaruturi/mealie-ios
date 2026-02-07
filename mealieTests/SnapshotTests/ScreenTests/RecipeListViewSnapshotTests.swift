import XCTest
import SnapshotTesting
import SwiftUI
import SwiftData
@testable import mealIO

@MainActor
final class RecipeListViewSnapshotTests: XCTestCase {

    func test_emptyState() {
        let apiService = TestAPIService()
        let ctx = makeTestModelContext()
        let recipesVM = RecipesViewModel(modelContext: ctx, mealieAPIService: apiService)

        let view = snapshotView(
            RecipeListView(mealieAPIService: apiService, recipesViewModel: recipesVM),
            authStatus: .authenticated(makeTestUser()),
            modelContext: ctx
        )
        assertViewSnapshot(view)
    }

    func test_withRecipes() {
        let apiService = TestAPIService()
        let ctx = makeTestModelContext()

        // Use a single recipe to avoid non-deterministic @Query ordering
        let recipe = makeTestRecipe(name: "Butter Chicken", slug: "butter-chicken")
        ctx.insert(recipe)
        try? ctx.save()

        let recipesVM = RecipesViewModel(modelContext: ctx, mealieAPIService: apiService)

        let view = snapshotView(
            RecipeListView(mealieAPIService: apiService, recipesViewModel: recipesVM),
            authStatus: .authenticated(makeTestUser()),
            modelContext: ctx
        )
        assertViewSnapshot(view)
    }
}
