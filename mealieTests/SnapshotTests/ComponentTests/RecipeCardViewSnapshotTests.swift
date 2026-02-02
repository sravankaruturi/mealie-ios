import XCTest
import SnapshotTesting
import SwiftUI
import SwiftData
@testable import mealIO

@MainActor
final class RecipeCardViewSnapshotTests: XCTestCase {
    func test_nonFavorite() {
        let recipe = makeTestRecipe(name: "Spaghetti Bolognese", isFavorite: false)
        let apiService = TestAPIService()
        let view = snapshotView(
            RecipeCardView(recipe: recipe, mealieAPIService: apiService)
        )
        assertComponentSnapshot(view, size: CGSize(width: 200, height: 160))
    }

    func test_favorite() {
        let recipe = makeTestRecipe(name: "Chicken Tikka Masala", isFavorite: true)
        let apiService = TestAPIService()
        let view = snapshotView(
            RecipeCardView(recipe: recipe, mealieAPIService: apiService)
        )
        assertComponentSnapshot(view, size: CGSize(width: 200, height: 160))
    }
}
