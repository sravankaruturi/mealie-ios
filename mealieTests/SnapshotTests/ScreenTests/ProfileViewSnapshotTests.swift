import XCTest
import SnapshotTesting
import SwiftUI
import SwiftData
@testable import mealIO

@MainActor
final class ProfileViewSnapshotTests: XCTestCase {

    func test_defaultState() {
        let apiService = TestAPIService()
        let ctx = makeTestModelContext()
        let recipesVM = RecipesViewModel(modelContext: ctx, mealieAPIService: apiService)

        let view = snapshotView(
            ProfileView(recipesViewModel: recipesVM, mealieAPIService: apiService),
            authStatus: .authenticated(makeTestUser()),
            modelContext: ctx
        )
        assertViewSnapshot(view)
    }

    func test_withRecipes() {
        let apiService = TestAPIService()
        let ctx = makeTestModelContext()

        let recipe1 = makeTestRecipe(name: "Chicken Soup", slug: "chicken-soup")
        let recipe2 = makeTestRecipe(name: "Beef Stew", slug: "beef-stew")
        let recipe3 = makeTestRecipe(name: "Garden Salad", slug: "garden-salad")

        ctx.insert(recipe1)
        ctx.insert(recipe2)
        ctx.insert(recipe3)
        try? ctx.save()

        let recipesVM = RecipesViewModel(modelContext: ctx, mealieAPIService: apiService)

        let view = snapshotView(
            ProfileView(recipesViewModel: recipesVM, mealieAPIService: apiService),
            authStatus: .authenticated(makeTestUser()),
            modelContext: ctx
        )
        assertViewSnapshot(view)
    }

    func test_syncing() {
        let apiService = TestAPIService()
        let ctx = makeTestModelContext()
        let recipesVM = RecipesViewModel(modelContext: ctx, mealieAPIService: apiService)
        recipesVM.isSyncing = true

        let view = snapshotView(
            ProfileView(recipesViewModel: recipesVM, mealieAPIService: apiService),
            authStatus: .authenticated(makeTestUser()),
            modelContext: ctx
        )
        assertViewSnapshot(view)
    }
}
