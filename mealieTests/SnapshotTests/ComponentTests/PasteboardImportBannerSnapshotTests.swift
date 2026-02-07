import XCTest
import SnapshotTesting
import SwiftUI
@testable import mealIO

@MainActor
final class PasteboardImportBannerSnapshotTests: XCTestCase {
    func test_default() {
        let view = PasteboardImportBanner(onImport: {}, onDismiss: {})
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 160))
    }
}
