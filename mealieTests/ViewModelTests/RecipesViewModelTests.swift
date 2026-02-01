import Foundation
import SwiftData
import Testing
@testable import mealIO

@MainActor
struct RecipesViewModelTests {

    private func makeVM(apiService: TestAPIService? = nil) -> (RecipesViewModel, TestAPIService) {
        let ctx = makeTestModelContext()
        let api = apiService ?? TestAPIService()
        let vm = RecipesViewModel(modelContext: ctx, mealieAPIService: api)
        return (vm, api)
    }

    // MARK: - shouldSyncRecipes() Tests

    @Test
    func shouldSync_noRecipes_returnsTrue() {
        let (vm, _) = makeVM()
        // Empty model context means no recipes
        #expect(vm.shouldSyncRecipes() == true)
    }

    @Test
    func shouldSync_neverSynced_returnsTrue() {
        let (vm, _) = makeVM()
        // Manually add a recipe to the array (not from DB)
        vm.recipes = [makeTestRecipe()]
        vm.lastSyncTime = nil
        #expect(vm.shouldSyncRecipes() == true)
    }

    @Test
    func shouldSync_recentSync_returnsFalse() {
        let (vm, _) = makeVM()
        vm.recipes = [makeTestRecipe()]
        vm.lastSyncTime = Date().addingTimeInterval(-60) // 1 minute ago
        #expect(vm.shouldSyncRecipes() == false)
    }

    @Test
    func shouldSync_staleSync_returnsTrue() {
        let (vm, _) = makeVM()
        vm.recipes = [makeTestRecipe()]
        vm.lastSyncTime = Date().addingTimeInterval(-360) // 6 minutes ago
        #expect(vm.shouldSyncRecipes() == true)
    }

    @Test
    func shouldSync_justUnderFiveMinutes_returnsFalse() {
        let (vm, _) = makeVM()
        vm.recipes = [makeTestRecipe()]
        vm.lastSyncTime = Date().addingTimeInterval(-299) // just under 5 minutes
        // The code uses `> fiveMinutes`, so under 5 minutes returns false
        #expect(vm.shouldSyncRecipes() == false)
    }

    // MARK: - Async Sync Tests

    @Test
    func syncRecipes_callsFetchAllRecipesOptimized() async {
        let (vm, api) = makeVM()
        await vm.syncRecipes()
        #expect(api.fetchAllRecipesOptimizedCallCount == 1)
        #expect(api.fetchAllRecipesCallCount == 0)
    }

    @Test
    func syncRecipes_setsIsSyncingAfterCompletion() async {
        let (vm, _) = makeVM()
        await vm.syncRecipes()
        #expect(vm.isSyncing == false)
    }

    @Test
    func forceSyncRecipes_callsFetchAllRecipesOptimizedWithEmptyArray() async {
        let (vm, api) = makeVM()
        await vm.forceSyncRecipes()
        // M1: forceSyncRecipes now uses optimized path with empty array (treats all as "new")
        #expect(api.fetchAllRecipesOptimizedCallCount == 1)
        #expect(api.fetchAllRecipesCallCount == 0)
    }
}
