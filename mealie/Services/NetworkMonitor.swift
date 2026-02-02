import Foundation
import Network

/// Observes network connectivity using `NWPathMonitor` and publishes changes.
///
/// Owned by ``AppState`` and injected into the SwiftUI environment so views
/// can reactively show an offline banner and services can gate API calls.
///
/// Usage:
/// ```swift
/// let monitor = NetworkMonitor()
/// monitor.start()
/// // Later…
/// if monitor.isConnected { /* safe to call API */ }
/// ```
@Observable
final class NetworkMonitor {

    /// Whether the device currently has a network path that is satisfied.
    var isConnected: Bool = true

    /// Callback invoked when connectivity transitions from offline → online.
    /// Used by ``SyncManager`` to trigger queue processing.
    var onReconnect: (() -> Void)?

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.mealie.networkMonitor")

    /// Creates a network monitor. Call ``start()`` to begin observing.
    init(monitor: NWPathMonitor = NWPathMonitor()) {
        self.monitor = monitor
    }

    /// Begins monitoring the default network path.
    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            let wasConnected = self?.isConnected ?? true
            let nowConnected = path.status == .satisfied

            DispatchQueue.main.async {
                self?.isConnected = nowConnected

                // Trigger reconnect callback on offline → online transition
                if !wasConnected && nowConnected {
                    self?.onReconnect?()
                }
            }
        }
        monitor.start(queue: queue)
    }

    /// Stops monitoring and cancels the underlying path monitor.
    func stop() {
        monitor.cancel()
    }
}
