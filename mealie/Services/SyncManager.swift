import Foundation
import SwiftData
import SwiftUI

/// JSON payload for a favorite toggle operation.
struct FavoritePayload: Codable {
    let slug: String
    let isFavorite: Bool
}

/// JSON payload for a meal plan creation operation.
struct MealPlanPayload: Codable {
    let date: Date
    let mealType: String
    let recipeId: String
}

/// Processes the ``PendingOperation`` queue, syncing local mutations to the Mealie server.
///
/// Operations are processed in FIFO order. Failed operations have their retry count
/// incremented and are retried with exponential backoff. Stale operations (> 7 days)
/// are automatically pruned.
///
/// The sync manager listens for network reconnection events via ``NetworkMonitor``
/// and automatically processes the queue when connectivity is restored.
@MainActor
@Observable
final class SyncManager {

    /// Whether a queue processing cycle is currently in progress.
    var isSyncing: Bool = false

    /// The number of pending operations awaiting sync.
    var pendingCount: Int = 0

    let apiService: MealieAPIServiceProtocol
    let modelContext: ModelContext
    let networkMonitor: NetworkMonitor

    /// Creates a sync manager and wires up the reconnection handler.
    init(apiService: MealieAPIServiceProtocol, modelContext: ModelContext, networkMonitor: NetworkMonitor) {
        self.apiService = apiService
        self.modelContext = modelContext
        self.networkMonitor = networkMonitor

        // Auto-process queue when connectivity is restored
        networkMonitor.onReconnect = { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                await self.processQueue()
            }
        }

        // Load initial pending count
        refreshPendingCount()
    }

    // MARK: - Enqueue

    /// Enqueues a new operation for later synchronization.
    /// - Parameters:
    ///   - type: The type of mutation to perform.
    ///   - entityId: The remote ID of the affected entity.
    ///   - payload: JSON-encodable data needed to replay the operation.
    func enqueueOperation(type: PendingOperationType, entityId: String, payload: Data? = nil) {
        let operation = PendingOperation(
            operationType: type,
            entityId: entityId,
            payload: payload
        )
        modelContext.insert(operation)
        do {
            try modelContext.save()
            refreshPendingCount()
            AppLogger.info(.sync, "Enqueued \(type.rawValue) for entity \(entityId)")
        } catch {
            modelContext.rollback()
            AppLogger.error(.sync, "Failed to persist pending operation: \(error)")
        }
    }

    // MARK: - Process Queue

    /// Processes all pending operations in FIFO order.
    ///
    /// Skips operations that have exceeded ``PendingOperation/maxRetries``
    /// or are not yet eligible for retry (exponential backoff).
    func processQueue() async {
        guard networkMonitor.isConnected else {
            AppLogger.info(.sync, "Skipping queue processing — offline")
            return
        }
        guard !isSyncing else {
            AppLogger.info(.sync, "Queue processing already in progress")
            return
        }

        isSyncing = true
        defer {
            isSyncing = false
            refreshPendingCount()
        }

        pruneStaleOperations()

        let operations = fetchPendingOperations()
        guard !operations.isEmpty else {
            AppLogger.info(.sync, "No pending operations to process")
            return
        }

        AppLogger.info(.sync, "Processing \(operations.count) pending operations")

        for operation in operations {
            // Skip if max retries exceeded
            guard operation.retryCount < PendingOperation.maxRetries else {
                AppLogger.warning(.sync, "Skipping operation \(operation.id) — max retries exceeded")
                continue
            }

            // Exponential backoff: wait 2^retryCount seconds between retries
            if let lastAttempt = operation.lastAttempt {
                let backoffSeconds = pow(2.0, Double(operation.retryCount))
                let eligibleDate = lastAttempt.addingTimeInterval(backoffSeconds)
                guard Date() >= eligibleDate else {
                    continue
                }
            }

            do {
                try await executeOperation(operation)
                // Success — remove from queue
                modelContext.delete(operation)
                do {
                    try modelContext.save()
                } catch {
                    AppLogger.error(.sync, "Failed to persist operation removal: \(error)")
                }
                AppLogger.info(.sync, "Completed \(operation.operationType) for \(operation.entityId)")
            } catch {
                // Failure — increment retry count
                operation.retryCount += 1
                operation.lastAttempt = Date()
                operation.errorMessage = error.localizedDescription
                do {
                    try modelContext.save()
                } catch {
                    AppLogger.error(.sync, "Failed to persist retry state: \(error)")
                }
                AppLogger.warning(.sync, "Failed \(operation.operationType) for \(operation.entityId): \(error.localizedDescription) (retry \(operation.retryCount))")
            }
        }
    }

    // MARK: - Prune

    /// Removes operations older than ``PendingOperation/maxAge`` (7 days).
    func pruneStaleOperations() {
        let cutoffDate = Date().addingTimeInterval(-PendingOperation.maxAge)
        let descriptor = FetchDescriptor<PendingOperation>(
            predicate: #Predicate { $0.createdAt < cutoffDate }
        )
        guard let staleOps = try? modelContext.fetch(descriptor) else { return }
        for op in staleOps {
            AppLogger.info(.sync, "Pruning stale operation \(op.id) (created \(op.createdAt))")
            modelContext.delete(op)
        }
        if !staleOps.isEmpty {
            do {
                try modelContext.save()
            } catch {
                AppLogger.error(.sync, "Failed to persist stale operation pruning: \(error)")
            }
        }
    }

    // MARK: - Private Helpers

    /// Fetches all pending operations sorted by creation date (FIFO).
    private func fetchPendingOperations() -> [PendingOperation] {
        let descriptor = FetchDescriptor<PendingOperation>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Dispatches a single operation to the appropriate API call.
    private func executeOperation(_ operation: PendingOperation) async throws {
        guard let type = operation.type else {
            AppLogger.error(.sync, "Unknown operation type: \(operation.operationType)")
            // Delete unknown operations so they don't clog the queue
            modelContext.delete(operation)
            do {
                try modelContext.save()
            } catch {
                AppLogger.error(.sync, "Failed to persist unknown operation removal: \(error)")
            }
            return
        }

        switch type {
        case .updateRecipe:
            try await executeRecipeUpdate(operation)
        case .toggleFavorite:
            try await executeFavoriteToggle(operation)
        case .createMealPlan:
            try await executeMealPlanCreate(operation)
        }
    }

    /// Replays a recipe update operation against the API.
    private func executeRecipeUpdate(_ operation: PendingOperation) async throws {
        // The payload contains the slug; we re-fetch the local recipe and build the API payload
        guard let payloadData = operation.payload,
              let slug = String(data: payloadData, encoding: .utf8) else {
            throw MealieAPIError.custom("Invalid recipe update payload")
        }

        // Find the local recipe by remoteId
        let entityId = operation.entityId
        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate { $0.remoteId == entityId }
        )
        guard let recipe = (try? modelContext.fetch(descriptor))?.first else {
            AppLogger.warning(.sync, "Recipe \(entityId) not found locally — removing stale operation")
            return
        }

        // Fetch the latest version from server to get the full recipe details for the update call
        // We'll use the locally stored data to update
        let recipeInput = buildRecipeInput(from: recipe, slug: slug)
        try await apiService.updateRecipe(slug: slug, recipeData: recipeInput)

        // Clear the local changes flag on success
        recipe.hasLocalChanges = false
        do {
            try modelContext.save()
        } catch {
            AppLogger.error(.sync, "Failed to persist hasLocalChanges reset: \(error)")
        }
    }

    /// Replays a favorite toggle operation against the API.
    private func executeFavoriteToggle(_ operation: PendingOperation) async throws {
        guard let payloadData = operation.payload else {
            throw MealieAPIError.custom("Invalid favorite toggle payload")
        }
        let payload = try JSONDecoder().decode(FavoritePayload.self, from: payloadData)

        if payload.isFavorite {
            try await apiService.addToFavorites(recipeSlug: payload.slug)
        } else {
            try await apiService.removeFromFavorites(recipeSlug: payload.slug)
        }
    }

    /// Replays a meal plan creation operation against the API.
    private func executeMealPlanCreate(_ operation: PendingOperation) async throws {
        guard let payloadData = operation.payload else {
            throw MealieAPIError.custom("Invalid meal plan create payload")
        }
        let payload = try JSONDecoder().decode(MealPlanPayload.self, from: payloadData)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let entryData: [String: Any] = [
            "date": formatter.string(from: payload.date),
            "mealType": payload.mealType,
            "recipeId": payload.recipeId
        ]
        try await apiService.createMealPlanEntry(entryData: entryData)

        // Mark the local entry as synced
        let localId = operation.entityId
        let descriptor = FetchDescriptor<MealPlanEntry>(
            predicate: #Predicate { $0.localId == localId }
        )
        if let entry = (try? modelContext.fetch(descriptor))?.first {
            entry.isSynced = true
            do {
                try modelContext.save()
            } catch {
                AppLogger.error(.sync, "Failed to persist meal plan sync status: \(error)")
            }
        }
    }

    /// Refreshes the ``pendingCount`` from the persistent store.
    func refreshPendingCount() {
        let descriptor = FetchDescriptor<PendingOperation>()
        pendingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    /// Builds a `Recipe-Input` API schema from a local Recipe model.
    ///
    /// This is a simplified version that captures the key fields. The full
    /// `EditRecipeViewModel.saveRecipe()` handles additional validation.
    private func buildRecipeInput(from recipe: Recipe, slug: String) -> Components.Schemas.Recipe_hyphen_Input {
        let apiIngredients = recipe.ingredients.sorted { $0.orderIndex < $1.orderIndex }.map { ingredient in
            Components.Schemas.RecipeIngredient_hyphen_Input(
                quantity: ingredient.quantity,
                unit: nil,
                food: nil,
                note: ingredient.note,
                disableAmount: true,
                display: ingredient.originalText,
                title: ingredient.title,
                originalText: ingredient.originalText,
                referenceId: nil
            )
        }

        let apiInstructions = recipe.instructions.sorted { $0.step < $1.step }.map { instruction in
            Components.Schemas.RecipeStep(
                id: nil,
                title: instruction.title,
                summary: nil,
                text: instruction.text,
                ingredientReferences: []
            )
        }

        return Components.Schemas.Recipe_hyphen_Input(
            id: recipe.remoteId,
            userId: recipe.userId,
            householdId: recipe.houseHoldId,
            groupId: recipe.groupId,
            name: recipe.name,
            slug: slug,
            image: recipe.image.flatMap { imageString in
                let clean = imageString.trimmingCharacters(in: .whitespacesAndNewlines)
                return clean.isEmpty ? nil : .init(stringLiteral: clean)
            },
            recipeServings: Double(recipe.recipeServings),
            recipeYieldQuantity: Double(recipe.recipeYieldQuantity),
            recipeYield: recipe.recipeYield,
            totalTime: recipe.totalTime,
            prepTime: recipe.prepTime,
            cookTime: recipe.cookTime,
            performTime: recipe.performTime,
            description: recipe.recipeDescription,
            recipeCategory: [],
            tags: [],
            tools: [],
            rating: recipe.rating.map { Double($0) },
            orgURL: recipe.orgUrl,
            dateAdded: recipe.dateAdded,
            dateUpdated: recipe.dateUpdated,
            createdAt: recipe.createdAt,
            update_at: recipe.update_at,
            lastMade: recipe.lastMade,
            recipeIngredient: apiIngredients,
            recipeInstructions: apiInstructions,
            nutrition: nil,
            settings: nil,
            assets: [],
            notes: [],
            extras: .init(),
            comments: []
        )
    }
}

// MARK: - Environment Key

/// Environment key for injecting the ``SyncManager`` into the SwiftUI view hierarchy.
private struct SyncManagerKey: EnvironmentKey {
    static let defaultValue: SyncManager? = nil
}

extension EnvironmentValues {
    var syncManager: SyncManager? {
        get { self[SyncManagerKey.self] }
        set { self[SyncManagerKey.self] = newValue }
    }
}
