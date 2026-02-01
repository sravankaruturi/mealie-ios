import Foundation
import Testing
@testable import mealIO

struct IngredientUnitTests {

    // MARK: - matchUnit() Tests

    @Test
    func matchUnit_directKey_returnsCup() {
        let unit = IngredientUnit.matchUnit("cup")
        #expect(unit.name == "Cup")
    }

    @Test
    func matchUnit_abbreviation_returnsTablespoon() {
        let unit = IngredientUnit.matchUnit("tbsp")
        #expect(unit.name == "Tablespoon")
    }

    @Test
    func matchUnit_plural_returnsCup() {
        let unit = IngredientUnit.matchUnit("Cups")
        #expect(unit.name == "Cup")
    }

    @Test
    func matchUnit_caseInsensitive_returnsCup() {
        let unit = IngredientUnit.matchUnit("CUP")
        #expect(unit.name == "Cup")
    }

    @Test
    func matchUnit_whitespace_returnsCup() {
        let unit = IngredientUnit.matchUnit(" cup ")
        #expect(unit.name == "Cup")
    }

    @Test
    func matchUnit_unknownFallback_returnsCustom() {
        let unit = IngredientUnit.matchUnit("unknown-unit")
        #expect(unit.name == "unknown-unit")
    }

    @Test
    func matchUnit_emptyString_returnsCustom() {
        let unit = IngredientUnit.matchUnit("")
        #expect(unit.name == "")
    }

    @Test
    func matchUnit_directKey_gram() {
        let unit = IngredientUnit.matchUnit("g")
        #expect(unit.name == "Gram")
    }

    @Test
    func matchUnit_abbreviation_ounce() {
        let unit = IngredientUnit.matchUnit("oz")
        #expect(unit.name == "Ounce")
    }
}
