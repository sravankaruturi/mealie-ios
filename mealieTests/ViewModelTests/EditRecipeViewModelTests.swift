import Foundation
import SwiftData
import Testing
@testable import mealIO

@MainActor
struct EditRecipeViewModelTests {

    private func makeVM(
        recipe: Recipe? = nil,
        ingredients: [Ingredient] = [],
        instructions: [Instruction] = []
    ) -> EditRecipeViewModel {
        let ctx = makeTestModelContext()
        let r = recipe ?? makeTestRecipe(
            name: "Test Recipe",
            slug: "test-recipe",
            ingredients: ingredients,
            instructions: instructions
        )
        return EditRecipeViewModel(
            modelContext: ctx,
            recipe: r,
            mealieAPIService: TestAPIService(),
            user: makeTestUser()
        )
    }

    // MARK: - Initialization

    @Test
    func init_populatesFieldsFromRecipe() {
        let recipe = makeTestRecipe(name: "Pasta", slug: "pasta")
        let vm = makeVM(recipe: recipe)
        #expect(vm.name == "Pasta")
        #expect(vm.slug == "pasta")
    }

    // MARK: - updateSlugBasedOnName

    @Test
    func updateSlugBasedOnName_generatesSlug() {
        let vm = makeVM()
        vm.name = "My Great Recipe"
        vm.updateSlugBasedOnName()
        #expect(vm.slug == "my-great-recipe")
    }

    @Test
    func updateSlugBasedOnName_trimsWhitespace() {
        let vm = makeVM()
        vm.name = " Spaced "
        vm.updateSlugBasedOnName()
        #expect(vm.slug == "spaced")
    }

    // MARK: - Ingredient Management

    @Test
    func addIngredient_setsSelectedAndPresentsSheet() {
        let vm = makeVM()
        vm.addIngredient()
        #expect(vm.isPresentingSheet == true)
        #expect(vm.selectedIngredient != nil)
    }

    @Test
    func saveIngredient_addsNewIngredient() {
        let vm = makeVM()
        let initialCount = vm.ingredients.count
        let newIngredient = Ingredient(orderIndex: 0, name: "Salt", quantity: 1, unit: IngredientUnit(name: "tsp"), originalText: "1 tsp salt", note: "")
        vm.saveIngredient(newIngredient)
        #expect(vm.ingredients.count == initialCount + 1)
    }

    @Test
    func saveIngredient_updatesExistingIngredient() {
        let ingredient = Ingredient(orderIndex: 0, name: "Flour", quantity: 2, unit: IngredientUnit(name: "cups"), originalText: "2 cups flour", note: "")
        let vm = makeVM(ingredients: [ingredient])
        let count = vm.ingredients.count
        // Modify the existing ingredient and save it
        ingredient.quantity = 3
        vm.saveIngredient(ingredient)
        #expect(vm.ingredients.count == count)
    }

    @Test
    func saveIngredient_updatesOrderIndices() {
        let i1 = Ingredient(orderIndex: 5, name: "A", quantity: 1, unit: IngredientUnit(name: ""), originalText: "", note: "")
        let i2 = Ingredient(orderIndex: 10, name: "B", quantity: 1, unit: IngredientUnit(name: ""), originalText: "", note: "")
        let vm = makeVM(ingredients: [i1, i2])
        let newIngredient = Ingredient(orderIndex: 99, name: "C", quantity: 1, unit: IngredientUnit(name: ""), originalText: "", note: "")
        vm.saveIngredient(newIngredient)
        for (index, ingredient) in vm.ingredients.enumerated() {
            #expect(ingredient.orderIndex == index)
        }
    }

    @Test
    func removeIngredient_removesAtIndex() {
        let i1 = Ingredient(orderIndex: 0, name: "Flour", quantity: 2, unit: IngredientUnit(name: "cups"), originalText: "", note: "")
        let i2 = Ingredient(orderIndex: 1, name: "Sugar", quantity: 1, unit: IngredientUnit(name: "cup"), originalText: "", note: "")
        let vm = makeVM(ingredients: [i1, i2])
        vm.removeIngredient(at: IndexSet(integer: 0))
        #expect(vm.ingredients.count == 1)
        #expect(vm.ingredients[0].name == "Sugar")
    }

    @Test
    func moveIngredient_reorders() {
        let i1 = Ingredient(orderIndex: 0, name: "First", quantity: 1, unit: IngredientUnit(name: ""), originalText: "", note: "")
        let i2 = Ingredient(orderIndex: 1, name: "Second", quantity: 1, unit: IngredientUnit(name: ""), originalText: "", note: "")
        let vm = makeVM(ingredients: [i1, i2])
        vm.moveIngredient(from: IndexSet(integer: 0), to: 2)
        #expect(vm.ingredients[0].name == "Second")
        #expect(vm.ingredients[1].name == "First")
    }

    // MARK: - Instruction Management

    @Test
    func addInstruction_appendsNewStep() {
        let vm = makeVM()
        let initialCount = vm.instructions.count
        vm.addInstruction()
        #expect(vm.instructions.count == initialCount + 1)
        #expect(vm.instructions.last?.step == initialCount + 1)
    }

    @Test
    func removeInstruction_removesAndRenumbers() {
        let inst1 = Instruction(step: 1, text: "Step 1")
        let inst2 = Instruction(step: 2, text: "Step 2")
        let inst3 = Instruction(step: 3, text: "Step 3")
        let vm = makeVM(instructions: [inst1, inst2, inst3])
        vm.removeInstruction(at: IndexSet(integer: 1))
        #expect(vm.instructions.count == 2)
        #expect(vm.instructions[0].step == 1)
        #expect(vm.instructions[1].step == 2)
        #expect(vm.instructions[1].text == "Step 3")
    }

    @Test
    func moveInstruction_reordersAndRenumbers() {
        let inst1 = Instruction(step: 1, text: "First")
        let inst2 = Instruction(step: 2, text: "Second")
        let inst3 = Instruction(step: 3, text: "Third")
        let vm = makeVM(instructions: [inst1, inst2, inst3])
        vm.moveInstruction(from: IndexSet(integer: 0), to: 3)
        #expect(vm.instructions[0].text == "Second")
        #expect(vm.instructions[2].text == "First")
        // Steps should be renumbered sequentially
        for (index, instruction) in vm.instructions.enumerated() {
            #expect(instruction.step == index + 1)
        }
    }

    @Test
    func addInstructionSection_createsSectionHeader() {
        let vm = makeVM()
        vm.addInstructionSection()
        let section = vm.instructions.last
        #expect(section?.title == "Section 1")
        #expect(section?.text == "")
    }

    @Test
    func addInstructionSection_incrementsSectionCount() {
        let vm = makeVM()
        vm.addInstructionSection()
        vm.addInstructionSection()
        let lastSection = vm.instructions.last
        #expect(lastSection?.title == "Section 2")
    }

    @Test
    func removeInstructionById_removesCorrectInstruction() {
        let inst1 = Instruction(step: 1, text: "Keep")
        let inst2 = Instruction(step: 2, text: "Remove")
        let vm = makeVM(instructions: [inst1, inst2])
        let idToRemove = vm.instructions[1].id
        vm.removeInstruction(id: idToRemove)
        #expect(vm.instructions.count == 1)
        #expect(vm.instructions[0].text == "Keep")
    }

    // MARK: - Offline-First / saveRecipe Tests

    @Test
    func saveRecipe_setsHasLocalChanges() async {
        let ctx = makeTestModelContext()
        let api = TestAPIService()
        let monitor = NetworkMonitor()
        monitor.isConnected = false
        let recipe = makeTestRecipe(name: "Old Name", slug: "old-name")
        ctx.insert(recipe)
        try? ctx.save()

        let vm = EditRecipeViewModel(
            modelContext: ctx,
            recipe: recipe,
            mealieAPIService: api,
            user: makeTestUser()
        )
        vm.networkMonitor = monitor
        vm.name = "Updated Name"

        await vm.saveRecipe()

        // Local save should succeed and flag hasLocalChanges
        #expect(recipe.hasLocalChanges == true)
        #expect(recipe.name == "Updated Name")
    }

    @Test
    func saveRecipe_enqueuesOnOffline() async {
        let ctx = makeTestModelContext()
        let api = TestAPIService()
        let monitor = NetworkMonitor()
        monitor.isConnected = false
        let syncMgr = SyncManager(apiService: api, modelContext: ctx, networkMonitor: monitor)

        let recipe = makeTestRecipe(name: "Offline Recipe", slug: "offline-recipe")
        ctx.insert(recipe)
        try? ctx.save()

        let vm = EditRecipeViewModel(
            modelContext: ctx,
            recipe: recipe,
            mealieAPIService: api,
            user: makeTestUser()
        )
        vm.syncManager = syncMgr
        vm.networkMonitor = monitor
        vm.name = "Offline Edit"

        await vm.saveRecipe()

        // Recipe saved locally
        #expect(recipe.name == "Offline Edit")
        #expect(recipe.hasLocalChanges == true)

        // No API update call since offline
        #expect(api.updateRecipeCallCount == 0)

        // Pending operation was enqueued
        let ops = (try? ctx.fetch(FetchDescriptor<PendingOperation>())) ?? []
        #expect(ops.count == 1)
        #expect(ops.first?.operationType == PendingOperationType.updateRecipe.rawValue)
    }

    @Test
    func saveRecipe_clearsHasLocalChangesOnSync() async {
        let ctx = makeTestModelContext()
        let api = TestAPIService()
        let monitor = NetworkMonitor()
        monitor.isConnected = true

        let recipe = makeTestRecipe(name: "Sync Recipe", slug: "sync-recipe")
        ctx.insert(recipe)
        try? ctx.save()

        let vm = EditRecipeViewModel(
            modelContext: ctx,
            recipe: recipe,
            mealieAPIService: api,
            user: makeTestUser()
        )
        vm.networkMonitor = monitor
        vm.name = "Synced Edit"

        await vm.saveRecipe()

        // API should have been called
        #expect(api.updateRecipeCallCount == 1)

        // hasLocalChanges should be cleared after successful sync
        #expect(recipe.hasLocalChanges == false)
    }
}
