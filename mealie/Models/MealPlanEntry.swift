import Foundation
import SwiftData

@Model
final class MealPlanEntry {
    var date: Date
    var mealType: String
    // By removing the @Relationship macro here, we break the circular dependency for the compiler.
    // SwiftData will infer the inverse relationship from the 'mealPlanEntries' property in the Recipe model.
    var recipe: Recipe?
    
    init(date: Date, mealType: String, recipe: Recipe? = nil) {
        self.date = date
        self.mealType = mealType
        self.recipe = recipe
    }
}
