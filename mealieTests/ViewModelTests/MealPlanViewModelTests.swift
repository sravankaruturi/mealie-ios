import Foundation
import SwiftData
import Testing
@testable import mealIO

@MainActor
struct MealPlanViewModelTests {

    // MARK: - generateShoppingList() Tests

    @Test
    func generateShoppingList_aggregatesIngredients() {
        let ctx = makeTestModelContext()
        let apiService = TestAPIService()
        let vm = MealPlanViewModel(apiService: apiService, modelContext: ctx)

        let r1 = makeTestRecipe(name: "Recipe 1", ingredients: [
            Ingredient(orderIndex: 0, name: "Flour", quantity: 2, unit: IngredientUnit(name: "cups"), originalText: "", note: "")
        ])
        let r2 = makeTestRecipe(name: "Recipe 2", ingredients: [
            Ingredient(orderIndex: 0, name: "Sugar", quantity: 1, unit: IngredientUnit(name: "cup"), originalText: "", note: "")
        ])
        let entries = [
            MealPlanEntry(date: Date(), mealType: "dinner", recipe: r1),
            MealPlanEntry(date: Date(), mealType: "dessert", recipe: r2)
        ]

        let list = vm.generateShoppingList(for: entries)
        #expect(list["Flour"] == 2.0)
        #expect(list["Sugar"] == 1.0)
    }

    @Test
    func generateShoppingList_sumsDuplicateIngredients() {
        let ctx = makeTestModelContext()
        let vm = MealPlanViewModel(apiService: TestAPIService(), modelContext: ctx)

        let r1 = makeTestRecipe(name: "R1", ingredients: [
            Ingredient(orderIndex: 0, name: "Flour", quantity: 2, unit: IngredientUnit(name: "cups"), originalText: "", note: "")
        ])
        let r2 = makeTestRecipe(name: "R2", ingredients: [
            Ingredient(orderIndex: 0, name: "Flour", quantity: 3, unit: IngredientUnit(name: "cups"), originalText: "", note: "")
        ])
        let entries = [
            MealPlanEntry(date: Date(), mealType: "lunch", recipe: r1),
            MealPlanEntry(date: Date(), mealType: "dinner", recipe: r2)
        ]

        let list = vm.generateShoppingList(for: entries)
        #expect(list["Flour"] == 5.0)
    }

    @Test
    func generateShoppingList_handlesNilRecipe() {
        let ctx = makeTestModelContext()
        let vm = MealPlanViewModel(apiService: TestAPIService(), modelContext: ctx)

        let entries = [MealPlanEntry(date: Date(), mealType: "lunch", recipe: nil)]
        let list = vm.generateShoppingList(for: entries)
        #expect(list.isEmpty)
    }

    @Test
    func generateShoppingList_emptyEntries_returnsEmptyDict() {
        let ctx = makeTestModelContext()
        let vm = MealPlanViewModel(apiService: TestAPIService(), modelContext: ctx)
        let list = vm.generateShoppingList(for: [])
        #expect(list.isEmpty)
    }

    // MARK: - Offline-First / createMealPlanEntry Tests

    @Test
    func createMealPlanEntry_savesLocally() async {
        let ctx = makeTestModelContext()
        let api = TestAPIService()
        let vm = MealPlanViewModel(apiService: api, modelContext: ctx)

        let recipe = makeTestRecipe(name: "Tacos", slug: "tacos")
        ctx.insert(recipe)

        await vm.createMealPlanEntry(date: Date(), mealType: "dinner", recipe: recipe)

        let entries = (try? ctx.fetch(FetchDescriptor<MealPlanEntry>())) ?? []
        #expect(entries.count == 1)
        #expect(entries.first?.mealType == "dinner")
    }

    @Test
    func createMealPlanEntry_enqueuesSyncWhenOffline() async {
        let ctx = makeTestModelContext()
        let api = TestAPIService()
        let monitor = NetworkMonitor()
        monitor.isConnected = false
        let syncMgr = SyncManager(apiService: api, modelContext: ctx, networkMonitor: monitor)
        let vm = MealPlanViewModel(apiService: api, modelContext: ctx)
        vm.syncManager = syncMgr
        vm.networkMonitor = monitor

        let recipe = makeTestRecipe(name: "Soup", slug: "soup")
        ctx.insert(recipe)

        await vm.createMealPlanEntry(date: Date(), mealType: "lunch", recipe: recipe)

        // Entry saved locally
        let entries = (try? ctx.fetch(FetchDescriptor<MealPlanEntry>())) ?? []
        #expect(entries.count == 1)

        // API was not called (offline)
        #expect(api.createMealPlanEntryCallCount == 0)

        // Pending operation was enqueued
        let ops = (try? ctx.fetch(FetchDescriptor<PendingOperation>())) ?? []
        #expect(ops.count == 1)
        #expect(ops.first?.operationType == PendingOperationType.createMealPlan.rawValue)
    }

    @Test
    func createMealPlanEntry_syncsWhenOnline() async {
        let ctx = makeTestModelContext()
        let api = TestAPIService()
        let monitor = NetworkMonitor()
        monitor.isConnected = true
        let vm = MealPlanViewModel(apiService: api, modelContext: ctx)
        vm.networkMonitor = monitor

        let recipe = makeTestRecipe(name: "Pizza", slug: "pizza")
        ctx.insert(recipe)

        await vm.createMealPlanEntry(date: Date(), mealType: "dinner", recipe: recipe)

        #expect(api.createMealPlanEntryCallCount == 1)

        // Entry should be marked synced
        let entries = (try? ctx.fetch(FetchDescriptor<MealPlanEntry>())) ?? []
        #expect(entries.first?.isSynced == true)
    }

    @Test
    func generateShoppingList_multipleIngredientsPerRecipe() {
        let ctx = makeTestModelContext()
        let vm = MealPlanViewModel(apiService: TestAPIService(), modelContext: ctx)

        let recipe = makeTestRecipe(name: "Full Recipe", ingredients: [
            Ingredient(orderIndex: 0, name: "Flour", quantity: 2, unit: IngredientUnit(name: "cups"), originalText: "", note: ""),
            Ingredient(orderIndex: 1, name: "Sugar", quantity: 1, unit: IngredientUnit(name: "cup"), originalText: "", note: ""),
            Ingredient(orderIndex: 2, name: "Butter", quantity: 0.5, unit: IngredientUnit(name: "cup"), originalText: "", note: "")
        ])
        let entries = [MealPlanEntry(date: Date(), mealType: "dinner", recipe: recipe)]

        let list = vm.generateShoppingList(for: entries)
        #expect(list.count == 3)
        #expect(list["Flour"] == 2.0)
        #expect(list["Sugar"] == 1.0)
        #expect(list["Butter"] == 0.5)
    }
}
