import XCTest
import SnapshotTesting
import SwiftUI
import SwiftData
@testable import mealIO

@MainActor
final class HomeViewSnapshotTests: XCTestCase {

    func test_emptyState() {
        let apiService = TestAPIService()
        let ctx = makeTestModelContext()
        let view = snapshotView(
            HomeView(mealieAPIService: apiService),
            authStatus: .authenticated(makeTestUser()),
            modelContext: ctx
        )
        assertViewSnapshot(view)
    }

    func test_withRecipes() {
        let apiService = TestAPIService()
        let ctx = makeTestModelContext()

        let recipe1 = makeTestRecipe(name: "Spaghetti Carbonara", slug: "spaghetti-carbonara", isFavorite: true)
        let recipe2 = makeTestRecipe(name: "Chicken Tikka Masala", slug: "chicken-tikka-masala")
        let recipe3 = makeTestRecipe(name: "Caesar Salad", slug: "caesar-salad")

        ctx.insert(recipe1)
        ctx.insert(recipe2)
        ctx.insert(recipe3)
        try? ctx.save()

        let view = snapshotView(
            HomeView(mealieAPIService: apiService),
            authStatus: .authenticated(makeTestUser()),
            modelContext: ctx
        )
        assertViewSnapshot(view)
    }

    func test_withFavoritesOnly() {
        let apiService = TestAPIService()
        let ctx = makeTestModelContext()

        let recipe1 = makeTestRecipe(name: "Pasta Primavera", slug: "pasta-primavera", isFavorite: true)
        let recipe2 = makeTestRecipe(name: "Grilled Salmon", slug: "grilled-salmon", isFavorite: true)

        ctx.insert(recipe1)
        ctx.insert(recipe2)
        try? ctx.save()

        let view = snapshotView(
            HomeView(mealieAPIService: apiService),
            authStatus: .authenticated(makeTestUser()),
            modelContext: ctx
        )
        assertViewSnapshot(view)
    }
}
