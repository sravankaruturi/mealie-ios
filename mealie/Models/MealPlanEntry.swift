import Foundation
import SwiftData

/// A meal plan entry linking a recipe to a specific date and meal type.
@Model
final class MealPlanEntry {
    var date: Date
    var mealType: String
    // By removing the @Relationship macro here, we break the circular dependency for the compiler.
    // SwiftData will infer the inverse relationship from the 'mealPlanEntries' property in the Recipe model.
    var recipe: Recipe?

    /// Locally generated identifier for entries not yet synced to the server.
    var localId: String = UUID().uuidString

    /// Whether this entry has been successfully pushed to the server.
    var isSynced: Bool = false

    /// Creates a meal plan entry for a specific date and meal.
    init(date: Date, mealType: String, recipe: Recipe? = nil) {
        self.date = date
        self.mealType = mealType
        self.recipe = recipe
        self.localId = UUID().uuidString
        self.isSynced = false
    }

    /// Default initializer required by SwiftData.
    init() {
        self.date = Date()
        self.mealType = ""
        self.recipe = nil
        self.localId = UUID().uuidString
        self.isSynced = false
    }
}
