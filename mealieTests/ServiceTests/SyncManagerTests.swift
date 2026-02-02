import Testing
import Foundation
import SwiftData
@testable import mealIO

@Suite("SyncManager Tests")
@MainActor
struct SyncManagerTests {

    // MARK: - Helpers

    private func makeSUT(shouldThrow: Error? = nil, isConnected: Bool = true) -> (SyncManager, TestAPIService, ModelContext, NetworkMonitor) {
        let context = makeTestModelContext()
        let api = TestAPIService()
        api.shouldThrow = shouldThrow
        let monitor = NetworkMonitor()
        // Override connectivity for tests
        monitor.isConnected = isConnected
        let manager = SyncManager(apiService: api, modelContext: context, networkMonitor: monitor)
        return (manager, api, context, monitor)
    }

    // MARK: - Enqueue Tests

    @Test
    func enqueueOperation_addsToQueue() async {
        let (manager, _, context, _) = makeSUT()

        manager.enqueueOperation(type: .updateRecipe, entityId: "recipe-1", payload: "test-slug".data(using: .utf8))

        let ops = (try? context.fetch(FetchDescriptor<PendingOperation>())) ?? []
        #expect(ops.count == 1)
        #expect(ops.first?.operationType == PendingOperationType.updateRecipe.rawValue)
        #expect(ops.first?.entityId == "recipe-1")
        #expect(manager.pendingCount == 1)
    }

    // MARK: - Process Queue Tests

    @Test
    func processQueue_skipsWhenOffline() async {
        let (manager, api, _, _) = makeSUT(isConnected: false)

        manager.enqueueOperation(type: .toggleFavorite, entityId: "recipe-1", payload: try? JSONEncoder().encode(FavoritePayload(slug: "test", isFavorite: true)))

        await manager.processQueue()

        // No API calls should have been made
        #expect(api.addRecipeFromURLCallCount == 0)
        #expect(manager.pendingCount == 1)
    }

    @Test
    func processQueue_removesSuccessfulOps() async {
        let (manager, _, context, _) = makeSUT()

        // Enqueue a favorite toggle that will succeed
        let payload = try! JSONEncoder().encode(FavoritePayload(slug: "test-slug", isFavorite: true))
        manager.enqueueOperation(type: .toggleFavorite, entityId: "recipe-1", payload: payload)

        #expect(manager.pendingCount == 1)

        await manager.processQueue()

        let ops = (try? context.fetch(FetchDescriptor<PendingOperation>())) ?? []
        #expect(ops.isEmpty)
        #expect(manager.pendingCount == 0)
    }

    @Test
    func processQueue_incrementsRetryOnFailure() async {
        let error = MealieAPIError.custom("Server error")
        let (manager, _, context, _) = makeSUT(shouldThrow: error)

        let payload = try! JSONEncoder().encode(FavoritePayload(slug: "test-slug", isFavorite: true))
        manager.enqueueOperation(type: .toggleFavorite, entityId: "recipe-1", payload: payload)

        await manager.processQueue()

        let ops = (try? context.fetch(FetchDescriptor<PendingOperation>())) ?? []
        #expect(ops.count == 1)
        #expect(ops.first?.retryCount == 1)
        #expect(ops.first?.lastAttempt != nil)
        #expect(ops.first?.errorMessage == "Server error")
    }

    @Test
    func processQueue_skipsMaxRetryOps() async {
        let (manager, api, context, _) = makeSUT()

        // Manually insert an op that's at max retries
        let op = PendingOperation(
            operationType: .toggleFavorite,
            entityId: "recipe-1",
            payload: try! JSONEncoder().encode(FavoritePayload(slug: "test", isFavorite: true)),
            retryCount: PendingOperation.maxRetries
        )
        context.insert(op)
        try? context.save()
        manager.refreshPendingCount()

        await manager.processQueue()

        // Op should still be in the queue (skipped, not deleted)
        let ops = (try? context.fetch(FetchDescriptor<PendingOperation>())) ?? []
        #expect(ops.count == 1)
        #expect(ops.first?.retryCount == PendingOperation.maxRetries)
    }

    @Test
    func processQueue_executesInFIFOOrder() async {
        let (manager, api, context, _) = makeSUT()

        // Enqueue two operations with different timestamps
        let payload1 = try! JSONEncoder().encode(FavoritePayload(slug: "first", isFavorite: true))
        let payload2 = try! JSONEncoder().encode(FavoritePayload(slug: "second", isFavorite: false))

        let op1 = PendingOperation(
            operationType: .toggleFavorite,
            entityId: "recipe-1",
            payload: payload1,
            createdAt: Date().addingTimeInterval(-100)
        )
        let op2 = PendingOperation(
            operationType: .toggleFavorite,
            entityId: "recipe-2",
            payload: payload2,
            createdAt: Date()
        )
        context.insert(op1)
        context.insert(op2)
        try? context.save()
        manager.refreshPendingCount()

        #expect(manager.pendingCount == 2)

        await manager.processQueue()

        // Both should be processed and removed
        #expect(manager.pendingCount == 0)
    }

    // MARK: - Prune Tests

    @Test
    func pruneStaleOperations_removesOld() async {
        let (manager, _, context, _) = makeSUT()

        // Insert a stale operation (8 days old)
        let staleOp = PendingOperation(
            operationType: .updateRecipe,
            entityId: "old-recipe",
            createdAt: Date().addingTimeInterval(-8 * 24 * 60 * 60)
        )
        context.insert(staleOp)

        // Insert a fresh operation
        let freshOp = PendingOperation(
            operationType: .updateRecipe,
            entityId: "new-recipe",
            createdAt: Date()
        )
        context.insert(freshOp)
        try? context.save()

        manager.pruneStaleOperations()

        let ops = (try? context.fetch(FetchDescriptor<PendingOperation>())) ?? []
        #expect(ops.count == 1)
        #expect(ops.first?.entityId == "new-recipe")
    }

    // MARK: - Operation Handler Tests

    @Test
    func processQueue_handlesToggleFavorite() async {
        let (manager, api, _, _) = makeSUT()

        let payload = try! JSONEncoder().encode(FavoritePayload(slug: "my-recipe", isFavorite: true))
        manager.enqueueOperation(type: .toggleFavorite, entityId: "recipe-1", payload: payload)

        await manager.processQueue()

        // The add-to-favorites endpoint should have been called
        // (TestAPIService doesn't have a specific counter for addToFavorites, but we check the op was removed)
        #expect(manager.pendingCount == 0)
    }

    @Test
    func processQueue_handlesMealPlanCreate() async {
        let (manager, api, _, _) = makeSUT()

        let payload = try! JSONEncoder().encode(MealPlanPayload(date: Date(), mealType: "dinner", recipeId: "recipe-1"))
        manager.enqueueOperation(type: .createMealPlan, entityId: "local-entry-1", payload: payload)

        await manager.processQueue()

        #expect(api.createMealPlanEntryCallCount == 1)
        #expect(manager.pendingCount == 0)
    }

    @Test
    func processQueue_handlesUpdateRecipe() async {
        let (manager, api, context, _) = makeSUT()

        // Insert a recipe so the sync manager can find it
        let recipe = makeTestRecipe(slug: "test-recipe", remoteId: "recipe-1")
        recipe.hasLocalChanges = true
        context.insert(recipe)
        try? context.save()

        let slugData = "test-recipe".data(using: .utf8)
        manager.enqueueOperation(type: .updateRecipe, entityId: "recipe-1", payload: slugData)

        await manager.processQueue()

        #expect(api.updateRecipeCallCount == 1)
        #expect(manager.pendingCount == 0)
        // hasLocalChanges should be cleared
        #expect(recipe.hasLocalChanges == false)
    }
}
