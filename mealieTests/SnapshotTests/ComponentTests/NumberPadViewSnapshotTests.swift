import XCTest
import SnapshotTesting
import SwiftUI
@testable import mealIO

@MainActor
final class NumberPadViewSnapshotTests: XCTestCase {
    func test_default() {
        let view = NumberPadView(
            onKeyPress: { _ in },
            onDelete: {}
        )
        .padding()
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 400))
    }
}
