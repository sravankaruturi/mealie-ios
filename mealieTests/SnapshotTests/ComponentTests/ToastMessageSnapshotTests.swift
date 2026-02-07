import XCTest
import SnapshotTesting
import SwiftUI
@testable import mealIO

@MainActor
final class ToastMessageSnapshotTests: XCTestCase {
    func test_errorType() {
        let view = ToastMessage(message: "Something went wrong.", type: .error, onDismiss: {})
            .padding()
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 80))
    }

    func test_warningType() {
        let view = ToastMessage(message: "Session is about to expire.", type: .warning, onDismiss: {})
            .padding()
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 80))
    }

    func test_successType() {
        let view = ToastMessage(message: "Recipe saved successfully!", type: .success, onDismiss: {})
            .padding()
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 80))
    }

    func test_infoType() {
        let view = ToastMessage(message: "Tip: swipe to dismiss.", type: .info, onDismiss: {})
            .padding()
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 80))
    }

    func test_withQueueCount() {
        let view = ToastMessage(message: "Multiple errors occurred.", type: .error, onDismiss: {}, queueCount: 3)
            .padding()
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 80))
    }
}
