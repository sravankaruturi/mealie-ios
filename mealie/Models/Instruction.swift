import Foundation
import SwiftData

@Model
final class Instruction {
    var step: Int
    var text: String
    // By removing the @Relationship macro here, we break the circular dependency for the compiler.
    // SwiftData will infer the inverse relationship from the 'instructions' property in the Recipe model.
    @Relationship(inverse: \Recipe.instructions)
    var recipe: Recipe?
    
    init(step: Int, text: String, recipe: Recipe? = nil) {
        self.step = step
        self.text = text
        self.recipe = recipe
    }
    
    // Default initializer for SwiftData
    init() {
        self.step = 0
        self.text = ""
        self.recipe = nil
    }

    // MARK: - Convenience Initializer for API Type
    convenience init(from apiObject: Components.Schemas.RecipeStep, step: Int) {
        self.init(
            step: step,
            text: apiObject.text
        )
    }
}
