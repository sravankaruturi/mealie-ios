import Testing
import Foundation
@testable import mealIO

@Suite("NetworkMonitor Tests")
struct NetworkMonitorTests {

    @Test
    func initialState_isConnected() {
        let monitor = NetworkMonitor()
        #expect(monitor.isConnected == true)
    }

    @Test
    func isConnected_canBeSetForTesting() {
        let monitor = NetworkMonitor()
        monitor.isConnected = false
        #expect(monitor.isConnected == false)
        monitor.isConnected = true
        #expect(monitor.isConnected == true)
    }
}
