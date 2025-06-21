import Foundation
import SwiftUI
import SwiftData

@Observable
final class RecipesViewModel {

    var isSyncing: Bool = false
    var error: String?
    let modelContext: ModelContext
    let apiService: MealieAPIService = .shared 
    var recipes: [Recipe]
    var lastSyncTime: Date?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.recipes = try! modelContext.fetch(FetchDescriptor<Recipe>())
    }
    
    func testDecoding() {

        // Paste your full JSON response here as a multi-line string
        let jsonString = """
        {
            "page": 1,
            "per_page": 50,
            "total": 2,
            "total_pages": 1,
            "items": [{
                "id": "7b41836c-9a06-42f9-a657-c88880478506",
                "userId": "9c0be747-d587-4943-b0a4-ce3ccb9d2ebc",
                "householdId": "8a4cd3ec-366f-4b8d-a287-08cdf00fff95",
                "groupId": "5f9cdc2a-4523-453b-9be0-39efcdbacb5b",
                "name": "Chole Recipe (Punjabi Chole Masala)",
                "slug": "chole-recipe-punjabi-chole-masala",
                "image": "ZjUc",
                "recipeServings": 4.0,
                "recipeYieldQuantity": 0.0,
                "recipeYield": "",
                "totalTime": "45",
                "prepTime": "10",
                "cookTime": null,
                "performTime": "35",
                "description": "Chole masala is a spicy & flavorful North Indian dish made with chole aka chickpeas, spices and herbs. Serve Punjabi chole with Bhatura, Basmati rice, poori or naan. Instructions for Stovetop and Instant pot included.",
                "recipeCategory": [],
                "tags": [{
                    "id": "a8ab1b52-7019-4a93-af91-aec05159467d",
                    "name": "Chole",
                    "slug": "chole"
                }, {
                    "id": "92c5fccc-9854-451a-b404-a9a7258096de",
                    "name": "Chole Masala",
                    "slug": "chole-masala"
                }, {
                    "id": "0f91a1ed-b007-48ee-877f-b8dbe1cf89dc",
                    "name": "Chole Recipe",
                    "slug": "chole-recipe"
                }, {
                    "id": "b7af0502-3fd9-4d6b-8402-7902ad725005",
                    "name": "Punjabi Chole",
                    "slug": "punjabi-chole"
                }],
                "tools": [],
                "rating": null,
                "orgURL": "https://www.indianhealthyrecipes.com/chole/",
                "dateAdded": "2025-06-17",
                "dateUpdated": "2025-06-17T01:12:40.812692+00:00",
                "createdAt": "2025-06-17T01:06:01.327503+00:00",
                "updatedAt": "2025-06-17T01:12:40.942266+00:00",
                "lastMade": null
            }, {
                "id": "1a255795-423e-4370-a3cd-3afcb71cac54",
                "userId": "9c0be747-d587-4943-b0a4-ce3ccb9d2ebc",
                "householdId": "8a4cd3ec-366f-4b8d-a287-08cdf00fff95",
                "groupId": "5f9cdc2a-4523-453b-9be0-39efcdbacb5b",
                "name": "Andhra Chicken Curry Recipe (Kodi Kura)",
                "slug": "andhra-chicken-curry-recipe-kodi-kura",
                "image": "jnd3",
                "recipeServings": 3.0,
                "recipeYieldQuantity": 0.0,
                "recipeYield": "",
                "totalTime": null,
                "prepTime": null,
                "cookTime": null,
                "performTime": null,
                "description": "Make this delicious Andhra style traditional chicken curry with pantry staples. It is spicy, delicious and flavorsome. It goes well with garelu, rice, chapati and onion raita.",
                "recipeCategory": [],
                "tags": [],
                "tools": [],
                "rating": null,
                "orgURL": "https://www.indianhealthyrecipes.com/andhra-chicken-curry-recipe-kodi-kura-with-step-by-step-pictures/",
                "dateAdded": "2025-06-13",
                "dateUpdated": "2025-06-13T23:20:37.187823+00:00",
                "createdAt": "2025-06-13T23:20:37.371263+00:00",
                "updatedAt": "2025-06-13T23:20:37.371265+00:00",
                "lastMade": null
            }],
            "next": null,
            "previous": null
        }
        """

        // You'll need to define all the Codable structs that match your generated ones.
        // For testing, you can paste the generated structs directly.
        // For example:

        // internal struct PaginationBase_RecipeSummary_: Codable, Hashable, Sendable { ... }
        // internal struct RecipeSummary: Codable, Hashable, Sendable { ... }
        // internal struct RecipeCategory: Codable, Hashable, Sendable { ... }
        // internal struct RecipeTag: Codable, Hashable, Sendable { ... }
        // internal struct RecipeTool: Codable, Hashable, Sendable { ... }
        // internal struct RecipeCommentOut_Output: Codable, Hashable, Sendable { ... }
        // internal struct IngredientFood_Output: Codable, Hashable, Sendable { ... }
        // internal struct Nutrition: Codable, Hashable, Sendable { ... }
        // internal struct RecipeSettings: Codable, Hashable, Sendable { ... }
        // internal struct RecipeAsset: Codable, Hashable, Sendable { ... }
        // internal struct RecipeNote: Codable, Hashable, Sendable { ... }
        // internal struct RecipeStep: Codable, Hashable, Sendable { ... }
        // internal struct IngredientReferences: Codable, Hashable, Sendable { ... }
        // internal struct Mealie__schema__recipe__recipe_comments__UserBase: Codable, Hashable, Sendable { ... }
        // internal struct UserBase_Output: Codable, Hashable, Sendable { ... }


        do {
            let decoder = JSONDecoder()
            // Configure date decoding strategy if necessary (for ISO 8601 strings)
            decoder.dateDecodingStrategy = .iso8601 // Assuming your date-time strings are ISO 8601

            let decodedResponse = try decoder.decode(Components.Schemas.PaginationBase_RecipeSummary_.self, from: Data(jsonString.utf8))
            print("Successfully decoded response: \(decodedResponse.total) items")
        } catch DecodingError.keyNotFound(let key, let context) {
            print("Decoding Error: Missing key '\(key.stringValue)' at path '\(context.codingPath.map { $0.stringValue }.joined(separator: "."))'")
            print("Debug Description: \(context.debugDescription)")
        } catch DecodingError.typeMismatch(let type, let context) {
            print("Decoding Error: Type mismatch for type '\(type)' at path '\(context.codingPath.map { $0.stringValue }.joined(separator: "."))'")
            print("Debug Description: \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            print("Decoding Error: Value not found for type '\(type)' at path '\(context.codingPath.map { $0.stringValue }.joined(separator: "."))'")
            print("Debug Description: \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(let context) {
            print("Decoding Error: Data corrupted: \(context.debugDescription)")
            print("Debug Description: \(context.underlyingError?.localizedDescription ?? "None")")
        } catch {
            print("An unknown decoding error occurred: \(error)")
        }
        
    }
    
    /// Check if we need to sync recipes based on last sync time
    func shouldSyncRecipes() -> Bool {
        // If we have no recipes, we definitely need to sync
        if recipes.isEmpty {
            return true
        }
        
        // If we've never synced, we need to sync
        guard let lastSync = lastSyncTime else {
            return true
        }
        
        // Check if it's been more than 5 minutes since last sync
        let timeSinceLastSync = Date().timeIntervalSince(lastSync)
        let fiveMinutes: TimeInterval = 5 * 60
        
        return timeSinceLastSync > fiveMinutes
    }
    
    func syncRecipes() async {
        
        // testDecoding()
        
        isSyncing = true
        error = nil
        defer { isSyncing = false }
        do {
            
            // Use optimized fetching that only downloads full details for updated recipes
            let remoteRecipes = try await apiService.fetchAllRecipesOptimized(existingRecipes: recipes)
            
            // Ensure all SwiftData operations happen on the main actor
            await MainActor.run {
                // Clear existing recipes and add the optimized results
                // This approach is simpler and more efficient than the previous merge logic
                for recipe in recipes {
                    modelContext.delete(recipe)
                }
                
                for recipe in remoteRecipes {
                    modelContext.insert(recipe)
                }
                
                try? modelContext.save()
                
                // Update our local recipes array
                self.recipes = remoteRecipes
                
                // Update last sync time
                self.lastSyncTime = Date()
            }
            
        } catch {
            self.error = error.localizedDescription
            print(self.error)
        }
    }

    func forceSyncRecipes() async {
        isSyncing = true
        error = nil
        defer { isSyncing = false }
        do {
            
            let remoteRecipes = try await apiService.fetchAllRecipes()
            
            await MainActor.run {
                for recipe in recipes {
                    modelContext.delete(recipe)
                }
                
                for recipe in remoteRecipes {
                    modelContext.insert(recipe)
                }
                
                try? modelContext.save()
                
                self.recipes = remoteRecipes
                
                self.lastSyncTime = Date()
            }
            
        } catch {
            self.error = error.localizedDescription
            print(self.error)
        }
    }
}
