import SwiftUI

/// A banner displayed when the device is offline, optionally showing pending operation count.
///
/// Place at the top of a view hierarchy (e.g. inside a `VStack` above main content).
/// The banner animates in/out based on ``NetworkMonitor/isConnected``.
///
/// ```swift
/// VStack {
///     OfflineBanner(networkMonitor: monitor, pendingCount: syncManager.pendingCount)
///     // ... main content
/// }
/// ```
struct OfflineBanner: View {

    let networkMonitor: NetworkMonitor
    var pendingCount: Int = 0

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.subheadline)

                if pendingCount > 0 {
                    Text("Offline · \(pendingCount) pending \(pendingCount == 1 ? "change" : "changes")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text("You are offline")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.orange)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

#Preview("Offline") {
    VStack {
        OfflineBanner(
            networkMonitor: {
                let m = NetworkMonitor()
                // Preview as offline
                return m
            }(),
            pendingCount: 3
        )
        Spacer()
    }
}
