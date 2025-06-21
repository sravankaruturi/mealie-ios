import Foundation
import SwiftData

/// This is based on the Recipe Input Schema Component.
@Model
final class Recipe {
    @Attribute(.unique) var remoteId: String
    var userId: String
    var groupId: String
    var houseHoldId: String
    var name: String?
    var slug: String
    var image: String?
    var recipeDescription: String
    
    var recipeServings: Int
    var recipeYieldQuantity: Int
    var recipeYield: String?
    var totalTime: String?
    var prepTime: String?
    var cookTime: String?
    var performTime: String?
    
    var rating: Int?
    var orgUrl: String?
    var dateAdded: String?
    var dateUpdated: String?
    var createdAt: String?
    var lastMade: String?
    var update_at: String? // Only use this when updating on the server
    
    var lastModified: Date
    
    // User preferences
    var isFavorite: Bool = false
    
    @Relationship(deleteRule: .nullify) var categories: [RecipeCategory] = []
    @Relationship(deleteRule: .nullify) var tags: [Tag] = []
    @Relationship(deleteRule: .nullify) var tools: [RecipeTool] = []
    @Relationship(deleteRule: .cascade) var ingredients: [Ingredient] = []
    @Relationship(deleteRule: .cascade) var instructions: [Instruction] = []
    
    // Optional properties that may not be implemented yet
    var nutrition: RecipeNutrition?
    var settings: RecipeSettings?
    var assets: [RecipeAsset] = []
    var notes: [RecipeNote] = []
    var extras: String = "" // Using string instead of [String: Any] for SwiftData compatibility
    var comments: [RecipeComment] = []
    
    // MARK: - Computed Properties
    
    /// The API ID used for image URLs and other API calls
    var apiId: String {
        return remoteId
    }
    
    /// Toggle the favorite status of this recipe
    func toggleFavorite() {
        isFavorite.toggle()
    }
    
    // MARK: - Initializers
    
    init(remoteId: String, userId: String, groupId: String, houseHoldId: String, name: String?, slug: String, image: String?, recipeDescription: String, recipeServings: Int, recipeYieldQuantity: Int, recipeYield: String?, totalTime: String?, prepTime: String?, cookTime: String?, performTime: String?, rating: Int?, orgUrl: String?, dateAdded: String?, dateUpdated: String?, createdAt: String?, lastMade: String?, update_at: String?, lastModified: Date = Date(), isFavorite: Bool = false, categories: [RecipeCategory] = [], tags: [Tag] = [], tools: [RecipeTool] = [], ingredients: [Ingredient] = [], instructions: [Instruction] = [], nutrition: RecipeNutrition? = nil, settings: RecipeSettings? = nil, assets: [RecipeAsset] = [], notes: [RecipeNote] = [], extras: String = "", comments: [RecipeComment] = []) {
        self.remoteId = remoteId
        self.userId = userId
        self.groupId = groupId
        self.houseHoldId = houseHoldId
        self.name = name
        self.slug = slug
        self.image = image
        self.recipeDescription = recipeDescription
        self.recipeServings = recipeServings
        self.recipeYieldQuantity = recipeYieldQuantity
        self.recipeYield = recipeYield
        self.totalTime = totalTime
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.performTime = performTime
        self.rating = rating
        self.orgUrl = orgUrl
        self.dateAdded = dateAdded
        self.dateUpdated = dateUpdated
        self.createdAt = createdAt
        self.lastMade = lastMade
        self.update_at = update_at
        self.lastModified = lastModified
        self.isFavorite = isFavorite
        self.categories = categories
        self.tags = tags
        self.tools = tools
        self.ingredients = ingredients
        self.instructions = instructions
        self.nutrition = nutrition
        self.settings = settings
        self.assets = assets
        self.notes = notes
        self.extras = extras
        self.comments = comments
    }
    
    // MARK: - Convenience Initializers for API Types
    
    convenience init(output: Components.Schemas.Recipe_hyphen_Output) {
        let remoteId = output.id ?? UUID().uuidString
        let userId = output.userId ?? ""
        let groupId = output.groupId ?? ""
        let houseHoldId = output.householdId ?? ""
        let name = output.name
        let slug = output.slug ?? ""
        let image = output.image.map { String(describing: $0) }
        let recipeDescription = output.description ?? ""
        let recipeServings = Int(output.recipeServings ?? 0)
        let recipeYieldQuantity = Int(output.recipeYieldQuantity ?? 0)
        let recipeYield = output.recipeYield
        let totalTime = output.totalTime
        let prepTime = output.prepTime
        let cookTime = output.cookTime
        let performTime = output.performTime
        let rating = output.rating != nil ? Int(output.rating!) : nil
        let orgUrl = output.orgURL
        let dateAdded = output.dateAdded
        let dateUpdated = output.dateUpdated
        let createdAt = output.createdAt
        let lastMade = output.lastMade
        let update_at = output.updatedAt // Note: Recipe-Output uses updatedAt, not update_at
        
        let ingredients = output.recipeIngredient?.compactMap { Ingredient(from: $0) } ?? []
        let instructions = output.recipeInstructions?.enumerated().compactMap { index, instruction_object in
            Instruction(from: instruction_object, step: index + 1)
        } ?? []

        self.init(
            remoteId: remoteId,
            userId: userId,
            groupId: groupId,
            houseHoldId: houseHoldId,
            name: name,
            slug: slug,
            image: image,
            recipeDescription: recipeDescription,
            recipeServings: recipeServings,
            recipeYieldQuantity: recipeYieldQuantity,
            recipeYield: recipeYield,
            totalTime: totalTime,
            prepTime: prepTime,
            cookTime: cookTime,
            performTime: performTime,
            rating: rating,
            orgUrl: orgUrl,
            dateAdded: dateAdded,
            dateUpdated: dateUpdated,
            createdAt: createdAt,
            lastMade: lastMade,
            update_at: update_at,
            isFavorite: false, // Default to false for API recipes
            ingredients: ingredients,
            instructions: instructions
        )
    }
    
    convenience init(input: Components.Schemas.Recipe_hyphen_Input) {
        let remoteId = input.id ?? UUID().uuidString
        let userId = input.userId ?? ""
        let groupId = input.groupId ?? ""
        let houseHoldId = input.householdId ?? ""
        let name = input.name
        let slug = input.slug ?? ""
        let image = input.image.map { String(describing: $0) }
        let recipeDescription = input.description ?? ""
        let recipeServings = Int(input.recipeServings ?? 0)
        let recipeYieldQuantity = Int(input.recipeYieldQuantity ?? 0)
        let recipeYield = input.recipeYield
        let totalTime = input.totalTime
        let prepTime = input.prepTime
        let cookTime = input.cookTime
        let performTime = input.performTime
        let rating = input.rating != nil ? Int(input.rating!) : nil
        let orgUrl = input.orgURL
        let dateAdded = input.dateAdded
        let dateUpdated = input.dateUpdated
        let createdAt = input.createdAt
        let lastMade = input.lastMade
        let update_at = input.update_at // Recipe-Input uses update_at
        
        self.init(
            remoteId: remoteId,
            userId: userId,
            groupId: groupId,
            houseHoldId: houseHoldId,
            name: name,
            slug: slug,
            image: image,
            recipeDescription: recipeDescription,
            recipeServings: recipeServings,
            recipeYieldQuantity: recipeYieldQuantity,
            recipeYield: recipeYield,
            totalTime: totalTime,
            prepTime: prepTime,
            cookTime: cookTime,
            performTime: performTime,
            rating: rating,
            orgUrl: orgUrl,
            dateAdded: dateAdded,
            dateUpdated: dateUpdated,
            createdAt: createdAt,
            lastMade: lastMade,
            update_at: update_at,
            isFavorite: false // Default to false for API recipes
        )
    }
    
    convenience init(summary: Components.Schemas.RecipeSummary) {
        let remoteId = summary.id ?? UUID().uuidString
        let userId = summary.userId ?? ""
        let groupId = summary.groupId ?? ""
        let houseHoldId = summary.householdId ?? ""
        let name = summary.name
        let slug = summary.slug ?? ""
        let image = summary.image.map { String(describing: $0) }
        let recipeDescription = summary.description ?? ""
        let recipeServings = Int(summary.recipeServings ?? 0)
        let recipeYieldQuantity = Int(summary.recipeYieldQuantity ?? 0)
        let recipeYield = summary.recipeYield
        let totalTime = summary.totalTime
        let prepTime = summary.prepTime
        let cookTime = summary.cookTime
        let performTime = summary.performTime
        // RecipeSummary doesn't have these fields, so use defaults
        let rating: Int? = nil
        let orgUrl: String? = nil
        let dateAdded: String? = nil
        let dateUpdated: String? = nil
        let createdAt: String? = nil
        let lastMade: String? = nil
        let update_at: String? = nil
        
        self.init(
            remoteId: remoteId,
            userId: userId,
            groupId: groupId,
            houseHoldId: houseHoldId,
            name: name,
            slug: slug,
            image: image,
            recipeDescription: recipeDescription,
            recipeServings: recipeServings,
            recipeYieldQuantity: recipeYieldQuantity,
            recipeYield: recipeYield,
            totalTime: totalTime,
            prepTime: prepTime,
            cookTime: cookTime,
            performTime: performTime,
            rating: rating,
            orgUrl: orgUrl,
            dateAdded: dateAdded,
            dateUpdated: dateUpdated,
            createdAt: createdAt,
            lastMade: lastMade,
            update_at: update_at,
            isFavorite: false // Default to false for API recipes
        )
    }
}

// MARK: - Supporting Classes

@Model
final class RecipeTool {
    var id: String
    var name: String
    var slug: String
    
    init(id: String, name: String, slug: String) {
        self.id = id
        self.name = name
        self.slug = slug
    }
}

@Model
final class RecipeCategory {
    var id: String
    var name: String
    var slug: String
    var groupId: String
    
    init(id: String, name: String, slug: String, groupId: String) {
        self.id = id
        self.name = name
        self.slug = slug
        self.groupId = groupId
    }
}

@Model
final class RecipeNutrition {
    var calories: Double?
    var fat: Double?
    var protein: Double?
    var carbohydrates: Double?
    var fiber: Double?
    var sugar: Double?
    var sodium: Double?
    
    init(calories: Double? = nil, fat: Double? = nil, protein: Double? = nil, 
         carbohydrates: Double? = nil, fiber: Double? = nil, sugar: Double? = nil, sodium: Double? = nil) {
        self.calories = calories
        self.fat = fat
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
    }
}

@Model
final class RecipeSettings {
    var isPublic: Bool // Changed from 'public' to avoid Swift keyword conflict
    var showNutrition: Bool
    var showAssets: Bool
    var landscapeView: Bool
    var disableComments: Bool
    var disableAmount: Bool
    
    init(isPublic: Bool = false, showNutrition: Bool = true, showAssets: Bool = true, 
         landscapeView: Bool = false, disableComments: Bool = false, disableAmount: Bool = false) {
        self.isPublic = isPublic
        self.showNutrition = showNutrition
        self.showAssets = showAssets
        self.landscapeView = landscapeView
        self.disableComments = disableComments
        self.disableAmount = disableAmount
    }
}

@Model
final class RecipeAsset {
    var id: String
    var name: String
    var icon: String
    var fileExtension: String // Changed from 'extension' to avoid Swift keyword conflict
    var fileName: String
    
    init(id: String, name: String, icon: String, fileExtension: String, fileName: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.fileExtension = fileExtension
        self.fileName = fileName
    }
}

@Model
final class RecipeNote {
    var id: String
    var title: String
    var text: String
    var recipeId: String
    
    init(id: String, title: String, text: String, recipeId: String) {
        self.id = id
        self.title = title
        self.text = text
        self.recipeId = recipeId
    }
}

@Model
final class RecipeComment {
    var id: String
    var text: String
    var recipeId: String
    var userId: String
    var createdAt: String
    
    init(id: String, text: String, recipeId: String, userId: String, createdAt: String = "") {
        self.id = id
        self.text = text
        self.recipeId = recipeId
        self.userId = userId
        self.createdAt = createdAt
    }
}
