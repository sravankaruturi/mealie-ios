import Foundation
import SwiftData

@Model
final class Instruction {
    var id: String?
    var step: Int
    var text: String
    var title: String? // Section title for grouping instructions
    // By removing the @Relationship macro here, we break the circular dependency for the compiler.
    // SwiftData will infer the inverse relationship from the 'instructions' property in the Recipe model.
    @Relationship(inverse: \Recipe.instructions)
    var recipe: Recipe?
    
    init(id: String? = nil, step: Int, text: String, title: String? = nil, recipe: Recipe? = nil) {
        self.id = id ?? UUID().uuidString
        self.step = step
        self.text = text
        self.title = title
        self.recipe = recipe
    }
    
    // Default initializer for SwiftData
    init() {
        self.id = UUID().uuidString
        self.step = 0
        self.text = ""
        self.title = nil
        self.recipe = nil
    }

    // MARK: - Convenience Initializer for API Type
    convenience init(from apiObject: Components.Schemas.RecipeStep, step: Int) {
        self.init(
            id: apiObject.id,
            step: step,
            text: apiObject.text,
            title: apiObject.title
        )
    }
}
