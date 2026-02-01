import Foundation
import SwiftData
import Testing
@testable import mealIO

@MainActor
struct AddRecipeViewModelTests {

    private func makeVM(apiService: TestAPIService? = nil) -> (AddRecipeViewModel, TestAPIService) {
        let ctx = makeTestModelContext()
        let api = apiService ?? TestAPIService()
        // Pre-populate the test API with a recipe that will be returned
        let testRecipe = makeTestRecipe(name: "Imported Recipe", slug: "test-slug")
        api.recipes = [testRecipe]
        api.recipeSlug = "test-slug"
        let vm = AddRecipeViewModel(apiService: api, modelContext: ctx)
        return (vm, api)
    }

    // MARK: - addRecipeFromURL Tests

    @Test
    func addRecipeFromURL_success_setsShowSuccessAndSlug() async {
        let (vm, _) = makeVM()
        await vm.addRecipeFromURL(URL(string: "https://example.com/recipe")!)
        #expect(vm.showSuccess == true)
        #expect(vm.newRecipeSlug == "test-slug")
        #expect(vm.error == nil)
    }

    @Test
    func addRecipeFromURL_failure_setsError() async {
        let api = TestAPIService()
        api.shouldThrow = MealieAPIError.networkError(NSError(domain: "test", code: -1))
        let (vm, _) = makeVM(apiService: api)
        await vm.addRecipeFromURL(URL(string: "https://example.com/recipe")!)
        #expect(vm.error != nil)
        #expect(vm.showSuccess == false)
    }

    @Test
    func addRecipeFromURL_setsIsLoadingFalseAfterCompletion() async {
        let (vm, _) = makeVM()
        await vm.addRecipeFromURL(URL(string: "https://example.com/recipe")!)
        #expect(vm.isLoading == false)
    }
}
