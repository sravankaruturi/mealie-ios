import Foundation
import Testing
@testable import mealIO

struct IngredientTests {

    // MARK: - extractUnitCandidate() Tests

    @Test
    func extractUnit_tablespoons_returnsTablespoons() {
        let result = Ingredient.extractUnitCandidate(from: "2 tablespoons oil")
        #expect(result == "tablespoons")
    }

    @Test
    func extractUnit_noUnit_returnsFirstNonNumber() {
        let result = Ingredient.extractUnitCandidate(from: "3 eggs")
        #expect(result == "eggs")
    }

    @Test
    func extractUnit_singleWord_returnsEmpty() {
        let result = Ingredient.extractUnitCandidate(from: "flour")
        #expect(result == "")
    }

    @Test
    func extractUnit_emptyString_returnsEmpty() {
        let result = Ingredient.extractUnitCandidate(from: "")
        #expect(result == "")
    }

    @Test
    func extractUnit_punctuationTrimmed() {
        let result = Ingredient.extractUnitCandidate(from: "2 cups, sifted flour")
        #expect(result == "cups")
    }
}
