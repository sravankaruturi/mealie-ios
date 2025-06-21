import Foundation

struct AppLogger {
    static func logRecipes(_ recipes: [Recipe], context: String) {
        print("📋 LOG: \(context)")
        print("    Total Recipes: \(recipes.count)")
        for recipe in recipes {
            print("    - '\(recipe.name ?? "Untitled")': \(recipe.ingredients.count) ingredients, \(recipe.instructions.count) instructions.")
        }
        print("----------------------------------")
    }
} 