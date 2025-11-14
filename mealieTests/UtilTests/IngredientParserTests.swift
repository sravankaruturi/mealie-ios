//
//  IngredientParserTests.swift
//  mealIO
//
//  Created by ChatGPT on 2024-06-01.
//

import Foundation
import Testing
@testable import mealIO

struct IngredientParserTests {

    @Test
    func parsesQuantityUnitAndName() {
        let parsed = IngredientParser.parse("2.5 cups flour")

        #expect(parsed?.quantity == 2.5)
        #expect(parsed?.unit == "cups")
        #expect(parsed?.name == "flour")
    }

    @Test
    func handlesMissingUnit() {
        let parsed = IngredientParser.parse("3 eggs")

        #expect(parsed?.quantity == 3)
        #expect(parsed?.unit == "")
        #expect(parsed?.name == "eggs")
    }

    @Test
    func handlesNoWhitespaceUnit() {
        let parsed = IngredientParser.parse("0.5tsp salt")

        #expect(parsed?.quantity == 0.5)
        #expect(parsed?.unit == "tsp")
        #expect(parsed?.name == "salt")
    }

    @Test
    func returnsNilForUnmatchedText() {
        #expect(IngredientParser.parse("pinch of salt") == nil)
    }
}
