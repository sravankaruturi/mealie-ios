import XCTest
import SnapshotTesting
import SwiftUI
@testable import mealIO

@MainActor
final class RecipeSectionHeaderSnapshotTests: XCTestCase {
    func test_detailStyle() {
        let view = VStack(alignment: .leading, spacing: 12) {
            RecipeSectionHeader(title: "For the Sauce")
            RecipeSectionHeader(title: "For the Pasta")
        }
        .padding()
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 120))
    }

    func test_editStyle() {
        let view = VStack(alignment: .leading, spacing: 12) {
            RecipeSectionHeader(title: "Preparation", style: .edit)
            RecipeSectionHeader(title: "Cooking", style: .edit)
        }
        .padding()
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 120))
    }
}
