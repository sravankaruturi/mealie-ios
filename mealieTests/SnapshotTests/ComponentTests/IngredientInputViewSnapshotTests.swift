import XCTest
import SnapshotTesting
import SwiftUI
@testable import mealIO

@MainActor
final class IngredientInputViewSnapshotTests: XCTestCase {
    func test_default() {
        let view = IngredientInputView(
            quantity: "2",
            selectedUnit: "Cup",
            itemName: "Flour",
            originalIngredient: nil,
            availableUnits: [],
            onSave: { _ in }
        )
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 600))
    }
}
