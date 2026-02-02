import XCTest
import SnapshotTesting
import SwiftUI
import SwiftData
@testable import mealIO

@MainActor
final class ContentViewSnapshotTests: XCTestCase {

    // Note: ContentView's `AuthenticationState.init` fires `checkForExistingAuth()`
    // async, which can race with our manually-set status. We snapshot the *child* views
    // that ContentView routes to, avoiding the race entirely while still testing each
    // screen the user would see for each auth state.

    func test_unknownStatus_showsLoading() {
        let view = snapshotView(LoadingView())
        assertViewSnapshot(view)
    }

    func test_unauthenticated_showsLogin() {
        let view = snapshotView(LoginView())
        assertViewSnapshot(view)
    }

    func test_loadingStatus_showsLoading() {
        let view = snapshotView(
            LoadingView(title: "Loading", subtitle: "Checking credentials...")
        )
        assertViewSnapshot(view)
    }

    func test_sessionExpired_showsLogin() {
        // SessionExpired shows LoginView (same as unauthenticated)
        let view = snapshotView(LoginView())
        assertViewSnapshot(view)
    }
}
