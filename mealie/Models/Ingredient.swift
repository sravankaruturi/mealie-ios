import Foundation
import SwiftData

@Model
final class Ingredient {
    var name: String
    var quantity: Double
    var unit: String
    var originalText: String
    var note: String
    // By removing the @Relationship macro here, we break the circular dependency for the compiler.
    // SwiftData will infer the inverse relationship from the 'ingredients' property in the Recipe model.
    var recipe: Recipe?
    
    init(name: String, quantity: Double, unit: String, originalText: String, note: String, recipe: Recipe? = nil) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.originalText = originalText
        self.note = note
        self.recipe = recipe
    }
}
