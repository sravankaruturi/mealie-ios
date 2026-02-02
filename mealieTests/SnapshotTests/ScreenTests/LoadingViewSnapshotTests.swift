import XCTest
import SnapshotTesting
import SwiftUI
@testable import mealIO

@MainActor
final class LoadingViewSnapshotTests: XCTestCase {

    func test_defaultState() {
        let view = snapshotView(LoadingView())
        assertViewSnapshot(view)
    }

    func test_customTitle() {
        let view = snapshotView(
            LoadingView(
                title: "Syncing your recipes...",
                subtitle: "This may take a moment."
            )
        )
        assertViewSnapshot(view)
    }

    func test_noSubtitle() {
        let view = snapshotView(
            LoadingView(
                title: "Almost ready...",
                subtitle: nil
            )
        )
        assertViewSnapshot(view)
    }
}
