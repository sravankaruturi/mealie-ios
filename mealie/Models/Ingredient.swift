import Foundation
import SwiftData

@Model
final class Ingredient {
    var orderIndex: Int
    var name: String
    var quantity: Double
    var unit: String
    var originalText: String
    var note: String
    // By removing the @Relationship macro here, we break the circular dependency for the compiler.
    // SwiftData will infer the inverse relationship from the 'ingredients' property in the Recipe model.
    @Relationship(inverse: \Recipe.ingredients)
    var recipe: Recipe?
    
    init(orderIndex: Int, name: String, quantity: Double, unit: String, originalText: String, note: String, recipe: Recipe? = nil) {
        self.orderIndex = orderIndex
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.originalText = originalText
        self.note = note
        self.recipe = recipe
    }
    
    // Default initializer for SwiftData
    init() {
        self.orderIndex = 0
        self.name = ""
        self.quantity = 0.0
        self.unit = ""
        self.originalText = ""
        self.note = ""
        self.recipe = nil
    }

    // MARK: - Convenience Initializer for API Type
    convenience init(from apiObject: Components.Schemas.RecipeIngredient_hyphen_Output, index: Int) {
        let displayText = apiObject.display ?? ""
        if let parsed = IngredientParser.parse(displayText) {
            self.init(
                orderIndex: index,
                name: parsed.name,
                quantity: parsed.quantity,
                unit: parsed.unit,
                originalText: displayText,
                note: apiObject.note ?? ""
            )
        } else {
            self.init(
                orderIndex: index,
                name: displayText,
                quantity: 1,
                unit: "",
                originalText: displayText,
                note: apiObject.note ?? ""
            )
        }
    }
}
