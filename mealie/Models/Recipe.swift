import Foundation
import SwiftData

@Model
final class Recipe {
    @Attribute(.unique) var remoteId: String
    var name: String
    var summary: String
    var prepTime: String
    var cookTime: String
    var imageURL: URL?
    var lastModified: Date
    var servings: String
    var isFavorite: Bool = false // local-only
    var lastCookedDate: Date? // local-only
    var userNotes: String = "" // local-only
    
    @Relationship(deleteRule: .cascade, inverse: \Ingredient.recipe) var ingredients: [Ingredient] = []
    @Relationship(deleteRule: .cascade, inverse: \Instruction.recipe) var instructions: [Instruction] = []
    @Relationship(deleteRule: .nullify, inverse: \Tag.recipes) var tags: [Tag] = []
    @Relationship(deleteRule: .cascade, inverse: \MealPlanEntry.recipe) var mealPlanEntries: [MealPlanEntry] = []
    
    init(remoteId: String, name: String, summary: String, prepTime: String, cookTime: String, imageURL: URL?, lastModified: Date, servings: String) {
        self.remoteId = remoteId
        self.name = name
        self.summary = summary
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.imageURL = imageURL
        self.lastModified = lastModified
        self.servings = servings
    }
} 
