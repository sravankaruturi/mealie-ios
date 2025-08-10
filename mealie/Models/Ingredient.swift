import Foundation
import SwiftData

struct IngredientUnit: Hashable, Identifiable, Codable {
    var id: String { name }
    var name: String
    var pluralName: String?
    var abbreviation: String?
    var unitDescription: String?
    // Add other fields as needed from OpenAPI
    
    static let standardUnits: [String: IngredientUnit] = [
        "cup": IngredientUnit(name: "Cup", pluralName: "Cups", abbreviation: "c"),
        "tablespoon": IngredientUnit(name: "Tablespoon", pluralName: "Tablespoons", abbreviation: "tbsp"),
        "teaspoon": IngredientUnit(name: "Teaspoon", pluralName: "Teaspoons", abbreviation: "tsp"),
        "ml": IngredientUnit(name: "ml", pluralName: "ml", abbreviation: "ml"),
        "l": IngredientUnit(name: "Litre", pluralName: "Litres", abbreviation: "l"),
        "g": IngredientUnit(name: "Gram", pluralName: "Grams", abbreviation: "g"),
        "kg": IngredientUnit(name: "Kilogram", pluralName: "Kilograms", abbreviation: "kg"),
        "oz": IngredientUnit(name: "Ounce", pluralName: "Ounces", abbreviation: "oz"),
        "lb": IngredientUnit(name: "Pound", pluralName: "Pounds", abbreviation: "lb"),
        "bunch": IngredientUnit(name: "Bunch", pluralName: "Bunches", abbreviation: nil),
        "item": IngredientUnit(name: "Item", pluralName: "Items", abbreviation: nil),
        "clove": IngredientUnit(name: "Clove", pluralName: "Cloves", abbreviation: nil),
        "piece": IngredientUnit(name: "Piece", pluralName: "Pieces", abbreviation: nil),
        "pinch": IngredientUnit(name: "Pinch", pluralName: "Pinches", abbreviation: nil),
        "dash": IngredientUnit(name: "Dash", pluralName: "Dashes", abbreviation: nil),
        // Add more as needed
    ]
    
    static func matchUnit(_ unitName: String) -> IngredientUnit {
        let lower = unitName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // Try direct match
        if let unit = standardUnits[lower] { return unit }
        // Try abbreviation match
        for unit in standardUnits.values {
            if let abbr = unit.abbreviation, abbr.lowercased() == lower { return unit }
        }
        // Try plural match
        for unit in standardUnits.values {
            if let plural = unit.pluralName, plural.lowercased() == lower { return unit }
        }
        // Fallback to custom unit
        return IngredientUnit(name: unitName)
    }
}

@Model
final class Ingredient : Sendable {
    var orderIndex: Int
    var name: String
    var quantity: Double
    var unit: IngredientUnit
    var originalText: String
    var note: String
    var title: String? // Section title for grouping ingredients
    // By removing the @Relationship macro here, we break the circular dependency for the compiler.
    // SwiftData will infer the inverse relationship from the 'ingredients' property in the Recipe model.
    @Relationship(inverse: \Recipe.ingredients)
    var recipe: Recipe?
    
    init(orderIndex: Int, name: String, quantity: Double, unit: IngredientUnit, originalText: String, note: String, title: String? = nil, recipe: Recipe? = nil) {
        self.orderIndex = orderIndex
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.originalText = originalText
        self.note = note
        self.title = title
        self.recipe = recipe
    }
    
    // Default initializer for SwiftData
    init() {
        self.orderIndex = 0
        self.name = ""
        self.quantity = 0.0
        self.unit = IngredientUnit(name: "")
        self.originalText = ""
        self.note = ""
        self.title = nil
        self.recipe = nil
    }

    // Helper to extract unit candidate from text
    static func extractUnitCandidate(from text: String) -> String {
        // Example: "2 tablespoons oil" -> "tablespoons"
        let components = text.split(separator: " ")
        guard components.count > 1 else { return "" }
        // Find the first component that is not a number or fraction
        for comp in components.dropFirst() {
            let s = comp.trimmingCharacters(in: .punctuationCharacters)
            // Skip numbers and common fractions
            if Double(s) == nil && !s.contains(where: { "¼½¾⅓⅔".contains($0) }) {
                return s.lowercased()
            }
        }
        return ""
    }

    // MARK: - Convenience Initializer for API Type
    convenience init(from apiObject: Components.Schemas.RecipeIngredient_hyphen_Output, index: Int) {
        let displayText = apiObject.display ?? ""
        // Prefer backend-normalized unit if available
        var unit: IngredientUnit
        if let unitEnum = apiObject.unit {
            if let value1 = unitEnum.value1 {
                let name = value1.name
                let plural = value1.pluralName
                let abbr = value1.abbreviation
                let desc = value1.description
                unit = IngredientUnit(name: name, pluralName: plural, abbreviation: abbr, unitDescription: desc)
            } else if let value2 = unitEnum.value2 {
                let name = value2.name
                let plural = value2.pluralName
                let abbr = value2.abbreviation
                let desc = value2.description
                unit = IngredientUnit(name: name, pluralName: plural, abbreviation: abbr, unitDescription: desc)
            } else {
                // Try to extract unit from display/originalText
                let text = apiObject.display ?? apiObject.originalText ?? ""
                let unitName = Ingredient.extractUnitCandidate(from: text)
                unit = IngredientUnit.matchUnit(unitName)
            }
        } else {
            // Try to extract unit from display/originalText
            let text = apiObject.display ?? apiObject.originalText ?? ""
            let unitName = Ingredient.extractUnitCandidate(from: text)
            unit = IngredientUnit.matchUnit(unitName)
        }
        // Extract food name from payload
        let foodName: String = apiObject.food?.value1?.name ?? apiObject.food?.value2?.name ?? displayText
        self.init(
            orderIndex: index,
            name: foodName,
            quantity: apiObject.quantity ?? 1,
            unit: unit,
            originalText: displayText,
            note: apiObject.note ?? "",
            title: apiObject.title
        )
    }
}
