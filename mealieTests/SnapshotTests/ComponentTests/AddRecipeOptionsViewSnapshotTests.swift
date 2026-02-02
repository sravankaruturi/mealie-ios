import XCTest
import SnapshotTesting
import SwiftUI
@testable import mealIO

@MainActor
final class AddRecipeOptionsViewSnapshotTests: XCTestCase {
    func test_default() {
        let view = AddRecipeOptionsView(onURLImport: {}, onManualImport: {})
        assertComponentSnapshot(view, size: CGSize(width: 200, height: 120))
    }
}
