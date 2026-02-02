import XCTest
import SnapshotTesting
import SwiftUI
@testable import mealIO

@MainActor
final class OfflineBannerSnapshotTests: XCTestCase {
    func test_offline() {
        let monitor = NetworkMonitor()
        monitor.isConnected = false
        let view = OfflineBanner(networkMonitor: monitor)
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 50))
    }

    func test_offlineWithPendingChanges() {
        let monitor = NetworkMonitor()
        monitor.isConnected = false
        let view = OfflineBanner(networkMonitor: monitor, pendingCount: 3)
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 50))
    }
}
