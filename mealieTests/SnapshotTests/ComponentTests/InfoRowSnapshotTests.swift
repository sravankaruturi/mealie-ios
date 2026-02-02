import XCTest
import SnapshotTesting
import SwiftUI
@testable import mealIO

@MainActor
final class InfoRowSnapshotTests: XCTestCase {
    func test_withoutSubtitle() {
        let view = InfoRow(icon: "envelope", title: "Email", value: "user@example.com")
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 80))
    }

    func test_withSubtitle() {
        let view = InfoRow(icon: "server.rack", title: "Server", value: "https://mealie.example.com", subtitle: "Connected")
        assertComponentSnapshot(view, size: CGSize(width: 390, height: 80))
    }
}
