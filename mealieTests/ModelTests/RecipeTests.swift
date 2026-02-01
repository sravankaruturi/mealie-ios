import Foundation
import Testing
@testable import mealIO

struct RecipeTests {

    // MARK: - toggleFavorite() Tests

    @Test
    func toggleFavorite_fromFalse_becomesTrue() {
        let recipe = makeTestRecipe(isFavorite: false)
        recipe.toggleFavorite()
        #expect(recipe.isFavorite == true)
    }

    @Test
    func toggleFavorite_fromTrue_becomesFalse() {
        let recipe = makeTestRecipe(isFavorite: true)
        recipe.toggleFavorite()
        #expect(recipe.isFavorite == false)
    }

    @Test
    func toggleFavorite_doubleToggle_returnsToOriginal() {
        let recipe = makeTestRecipe(isFavorite: false)
        recipe.toggleFavorite()
        recipe.toggleFavorite()
        #expect(recipe.isFavorite == false)
    }
}
