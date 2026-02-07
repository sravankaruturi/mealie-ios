import XCTest
import SnapshotTesting
import SwiftUI
@testable import mealIO

@MainActor
final class AddItemButtonSnapshotTests: XCTestCase {
    func test_addIngredient() {
        let view = AddItemButton(title: "Add Ingredient") {}
            .padding()
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 60))
    }

    func test_addStep() {
        let view = AddItemButton(title: "Add Step") {}
            .padding()
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 60))
    }
}
