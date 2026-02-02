import XCTest
import SnapshotTesting
import SwiftUI
import SwiftData
@testable import mealIO

@MainActor
final class AppFlowSnapshotTests: XCTestCase {

    private var apiService: TestAPIService!
    private var keychain: MockKeychainService!
    private var authService: MockAuthenticationService!
    private var modelContext: ModelContext!

    override func setUp() {
        super.setUp()
        apiService = TestAPIService()
        keychain = MockKeychainService()
        authService = MockAuthenticationService()
        modelContext = makeTestModelContext()
    }

    // MARK: - Authentication Flow

    func test_flow_01_appLaunch_showsLoading() {
        let view = LoadingView()
        assertViewSnapshot(snapshotView(view))
    }

    func test_flow_02_unauthenticated_showsLogin() {
        let authState = AuthenticationState(keychainService: keychain, authService: authService)
        authState.status = .unauthenticated
        let view = LoginBodyView(viewModel: LoginViewModel(authState: authState))
        assertViewSnapshot(snapshotView(view))
    }

    func test_flow_03_loginForm_filledIn() {
        let authState = AuthenticationState(keychainService: keychain, authService: authService)
        authState.status = .unauthenticated
        let vm = LoginViewModel(authState: authState)
        vm.serverURL = "https://mealie.example.com"
        vm.username = "chef@example.com"
        vm.password = "password123"
        let view = LoginBodyView(viewModel: vm)
        assertViewSnapshot(snapshotView(view))
    }

    // MARK: - Main App Flow

    func test_flow_04_homeScreen_withRecipes() {
        // Insert test recipes for @Query to pick up
        let r1 = makeTestRecipe(name: "Spaghetti Carbonara", slug: "spaghetti-carbonara", isFavorite: true)
        let r2 = makeTestRecipe(name: "Chocolate Chip Cookies", slug: "chocolate-cookies", isFavorite: true)
        let r3 = makeTestRecipe(name: "Grilled Chicken Salad", slug: "grilled-chicken-salad")
        modelContext.insert(r1); modelContext.insert(r2); modelContext.insert(r3)
        try? modelContext.save()

        let view = HomeView(mealieAPIService: apiService)
        assertViewSnapshot(snapshotView(view, modelContext: modelContext))
    }

    func test_flow_05_recipeList() {
        let r1 = makeTestRecipe(name: "Spaghetti Carbonara", slug: "spaghetti-carbonara")
        let r2 = makeTestRecipe(name: "Chocolate Cookies", slug: "chocolate-cookies", isFavorite: true)
        let r3 = makeTestRecipe(name: "Grilled Chicken", slug: "grilled-chicken")
        modelContext.insert(r1); modelContext.insert(r2); modelContext.insert(r3)
        try? modelContext.save()

        let vm = RecipesViewModel(modelContext: modelContext, mealieAPIService: apiService)
        vm.recipes = [r1, r2, r3]
        let view = RecipeListView(mealieAPIService: apiService, recipesViewModel: vm)
        assertViewSnapshot(snapshotView(view, modelContext: modelContext))
    }

    func test_flow_06_recipeDetail() {
        let ingredients = [
            Ingredient(orderIndex: 0, name: "Spaghetti", quantity: 400, unit: IngredientUnit(name: "Grams"), originalText: "400g Spaghetti", note: ""),
            Ingredient(orderIndex: 1, name: "Eggs", quantity: 4, unit: IngredientUnit(name: "Item"), originalText: "4 Eggs", note: "large"),
            Ingredient(orderIndex: 2, name: "Parmesan", quantity: 100, unit: IngredientUnit(name: "Grams"), originalText: "100g Parmesan", note: "grated"),
        ]
        let instructions = [
            Instruction(step: 1, text: "Boil water and cook spaghetti until al dente."),
            Instruction(step: 2, text: "Whisk eggs with grated parmesan in a bowl."),
            Instruction(step: 3, text: "Drain pasta, toss with egg mixture while still hot."),
        ]
        let recipe = makeTestRecipe(name: "Spaghetti Carbonara", slug: "spaghetti-carbonara", ingredients: ingredients, instructions: instructions)
        let view = NavigationStack { RecipeDetailView(recipe: recipe, mealieAPIService: apiService) }
        assertViewSnapshot(snapshotView(view, modelContext: modelContext))
    }

    func test_flow_07_editRecipe() {
        let recipe = makeTestRecipe(name: "Spaghetti Carbonara", slug: "spaghetti-carbonara")
        let user = makeTestUser()
        let view = NavigationStack {
            EditRecipeBodyView(recipe: recipe, modelContext: modelContext, mealieAPIService: apiService, user: user, isNewRecipe: false)
        }
        assertViewSnapshot(snapshotView(view, modelContext: modelContext))
    }

    func test_flow_08_profileScreen() {
        let vm = RecipesViewModel(modelContext: modelContext, mealieAPIService: apiService)
        vm.recipes = [makeTestRecipe(), makeTestRecipe(name: "Recipe 2", slug: "recipe-2")]
        let view = ProfileView(recipesViewModel: vm, mealieAPIService: apiService)
        assertViewSnapshot(snapshotView(view, authStatus: .authenticated(User.sampleData), modelContext: modelContext))
    }

    // MARK: - Edge Cases

    func test_flow_09_offlineBanner() {
        let monitor = NetworkMonitor()
        monitor.isConnected = false
        let view = OfflineBanner(networkMonitor: monitor, pendingCount: 2)
            .frame(maxWidth: .infinity)
        assertViewSnapshot(snapshotView(view, isConnected: false))
    }

    func test_flow_10_sessionExpired() {
        let authState = AuthenticationState(keychainService: keychain, authService: authService)
        authState.status = .sessionExpired
        let view = LoginBodyView(viewModel: LoginViewModel(authState: authState))
        assertViewSnapshot(snapshotView(view))
    }

    func test_flow_11_errorToast() {
        let view = ToastMessage(message: "Failed to save recipe. Please try again.", type: .error, onDismiss: {}, queueCount: 0)
            .padding()
        assertViewSnapshot(snapshotView(view))
    }

    func test_flow_12_successToast() {
        let view = ToastMessage(message: "Recipe saved successfully!", type: .success, onDismiss: {}, queueCount: 0)
            .padding()
        assertViewSnapshot(snapshotView(view))
    }

    func test_flow_13_importFromURL() {
        let vm = RecipesViewModel(modelContext: modelContext, mealieAPIService: apiService)
        let view = NavigationStack {
            ImportRecipeFromURLContentView(modelContext: modelContext, mealieAPIService: apiService, recipesViewModel: vm, onRecipeImported: nil)
        }
        assertViewSnapshot(snapshotView(view, modelContext: modelContext))
    }

    func test_flow_14_addRecipeOptions() {
        let view = AddRecipeOptionsView(onURLImport: {}, onManualImport: {})
            .padding()
            .frame(maxWidth: .infinity, alignment: .trailing)
        assertViewSnapshot(snapshotView(view))
    }

    func test_flow_15_newRecipe() {
        let recipe = Recipe(
            remoteId: "", userId: "", groupId: "", houseHoldId: "",
            name: "", slug: "", image: nil, recipeDescription: "",
            recipeServings: 0, recipeYieldQuantity: 0, recipeYield: "",
            totalTime: nil, prepTime: nil, cookTime: nil, performTime: nil,
            rating: nil, orgUrl: nil, dateAdded: nil, dateUpdated: nil,
            createdAt: nil, lastMade: nil, update_at: nil,
            isFavorite: false, ingredients: [], instructions: []
        )
        let user = makeTestUser()
        let view = NavigationStack {
            EditRecipeBodyView(recipe: recipe, modelContext: modelContext, mealieAPIService: apiService, user: user, isNewRecipe: true)
        }
        assertViewSnapshot(snapshotView(view, modelContext: modelContext))
    }
}
