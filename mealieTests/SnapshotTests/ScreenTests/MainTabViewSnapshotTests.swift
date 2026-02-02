import XCTest
import SnapshotTesting
import SwiftUI
import SwiftData
@testable import mealIO

@MainActor
final class MainTabViewSnapshotTests: XCTestCase {

    func test_defaultState() {
        let apiService = TestAPIService()
        let view = snapshotView(
            MainTabView(mealieAPIService: apiService),
            authStatus: .authenticated(makeTestUser())
        )
        assertViewSnapshot(view)
    }

    func test_offlineBanner() {
        let apiService = TestAPIService()
        let view = snapshotView(
            MainTabView(mealieAPIService: apiService),
            authStatus: .authenticated(makeTestUser()),
            isConnected: false
        )
        assertViewSnapshot(view)
    }
}
