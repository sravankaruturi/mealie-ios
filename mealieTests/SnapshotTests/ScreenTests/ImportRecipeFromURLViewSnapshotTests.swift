import XCTest
import SnapshotTesting
import SwiftUI
import SwiftData
@testable import mealIO

@MainActor
final class ImportRecipeFromURLViewSnapshotTests: XCTestCase {

    func test_defaultState() {
        let apiService = TestAPIService()
        let ctx = makeTestModelContext()
        let recipesVM = RecipesViewModel(modelContext: ctx, mealieAPIService: apiService)

        let view = snapshotView(
            ImportRecipeFromURLContentView(
                modelContext: ctx,
                mealieAPIService: apiService,
                recipesViewModel: recipesVM
            ),
            authStatus: .authenticated(makeTestUser()),
            modelContext: ctx
        )
        assertViewSnapshot(view)
    }

    func test_withCallback() {
        let apiService = TestAPIService()
        let ctx = makeTestModelContext()
        let recipesVM = RecipesViewModel(modelContext: ctx, mealieAPIService: apiService)

        let view = snapshotView(
            ImportRecipeFromURLContentView(
                modelContext: ctx,
                mealieAPIService: apiService,
                recipesViewModel: recipesVM,
                onRecipeImported: { _ in }
            ),
            authStatus: .authenticated(makeTestUser()),
            modelContext: ctx
        )
        assertViewSnapshot(view)
    }
}
