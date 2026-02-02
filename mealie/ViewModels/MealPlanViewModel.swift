import Foundation
import SwiftData

@MainActor
@Observable
/// Manages meal planning operations and shopping list generation.
final class MealPlanViewModel {

    var error: String?
    var isLoading: Bool = false
    let apiService: MealieAPIServiceProtocol
    let modelContext: ModelContext

    /// Optional sync manager for enqueueing operations when offline.
    var syncManager: SyncManager?
    /// Optional network monitor for checking connectivity before API calls.
    var networkMonitor: NetworkMonitor?

    /// Creates a meal plan view model with API and local storage access.
    init(apiService: MealieAPIServiceProtocol, modelContext: ModelContext) {
        self.apiService = apiService
        self.modelContext = modelContext
    }

    /// Creates a new meal plan entry, saving locally first then attempting server sync.
    ///
    /// If offline or the API call fails, a ``PendingOperation`` is enqueued
    /// for later synchronization by the ``SyncManager``.
    func createMealPlanEntry(date: Date, mealType: String, recipe: Recipe) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        // Save locally first
        let entry = MealPlanEntry(date: date, mealType: mealType, recipe: recipe)
        modelContext.insert(entry)
        do {
            try modelContext.save()
            AppLogger.info(.recipes, "Meal plan entry saved locally")
        } catch {
            self.error = "Failed to save meal plan entry locally: \(error.localizedDescription)"
            AppLogger.error(.recipes, "Failed to save meal plan entry locally: \(error)")
            return
        }

        // Attempt server sync
        let isOnline = networkMonitor?.isConnected ?? true
        if isOnline {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            let entryData: [String: Any] = [
                "date": formatter.string(from: date),
                "mealType": mealType,
                "recipeId": recipe.remoteId
            ]
            do {
                try await apiService.createMealPlanEntry(entryData: entryData)
                entry.isSynced = true
                try? modelContext.save()
                AppLogger.info(.recipes, "Meal plan entry synced to server")
            } catch {
                AppLogger.warning(.recipes, "API call failed, enqueueing meal plan creation: \(error.localizedDescription)")
                enqueueMealPlanSync(entry: entry, date: date, mealType: mealType, recipeId: recipe.remoteId)
            }
        } else {
            AppLogger.info(.recipes, "Offline — enqueueing meal plan creation for later sync")
            enqueueMealPlanSync(entry: entry, date: date, mealType: mealType, recipeId: recipe.remoteId)
        }
    }

    /// Enqueues a meal plan creation for later synchronization.
    private func enqueueMealPlanSync(entry: MealPlanEntry, date: Date, mealType: String, recipeId: String) {
        let payload = MealPlanPayload(date: date, mealType: mealType, recipeId: recipeId)
        guard let payloadData = try? JSONEncoder().encode(payload) else { return }
        syncManager?.enqueueOperation(
            type: .createMealPlan,
            entityId: entry.localId,
            payload: payloadData
        )
    }

    /// Generates a combined shopping list from the given recipes.
    func generateShoppingList(for entries: [MealPlanEntry]) -> [String: Double] {
        // Consolidate all ingredients by name and sum quantities
        var shoppingList: [String: Double] = [:]
        for entry in entries {
            guard let recipe = entry.recipe else { continue }
            for ingredient in recipe.ingredients {
                shoppingList[ingredient.name, default: 0] += ingredient.quantity
            }
        }
        return shoppingList
    }
}
