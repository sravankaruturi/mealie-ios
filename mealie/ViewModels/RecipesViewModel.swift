import Foundation
import SwiftData

@Observable
final class RecipesViewModel {
    // FIX: Removed @Published property wrappers.
    // The @Observable macro automatically makes these properties observable.
    var isSyncing: Bool = false
    var error: String?
    let modelContext: ModelContext
    let apiService: MealieAPIService = .shared
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func syncRecipes() async {
        isSyncing = true
        error = nil
        defer { isSyncing = false }
        do {
            let recipes = try await apiService.fetchAllRecipes()
            // Save to SwiftData (local-first)
            for recipe in recipes {
                // To avoid duplicates, you might want to check if the recipe already exists
                // before inserting. This is a simple insertion for now.
                modelContext.insert(recipe)
            }
            try modelContext.save()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
