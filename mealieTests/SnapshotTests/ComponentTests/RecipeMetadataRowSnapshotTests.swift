import XCTest
import SnapshotTesting
import SwiftUI
@testable import mealIO

@MainActor
final class RecipeMetadataRowSnapshotTests: XCTestCase {
    func test_multipleItems() {
        let view = RecipeMetadataRow(items: [
            .init(icon: "person.2", value: "4"),
            .init(icon: "timer", value: "15 min"),
            .init(icon: "flame", value: "30 min"),
        ])
        .font(.subheadline)
        .foregroundColor(.secondary)
        .padding()
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 60))
    }

    func test_singleItem() {
        let view = RecipeMetadataRow(items: [.init(icon: "person.2", value: "4")])
            .font(.subheadline).foregroundColor(.secondary).padding()
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 60))
    }

    func test_filteredEmpty() {
        let view = RecipeMetadataRow(items: RecipeMetadataRow.filtered([
            .init(icon: "person.2", value: "4"),
            .init(icon: "timer", value: ""),
            .init(icon: "flame", value: "  "),
        ]))
        .font(.subheadline).foregroundColor(.secondary).padding()
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 60))
    }
}
