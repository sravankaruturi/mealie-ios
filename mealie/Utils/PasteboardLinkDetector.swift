import UIKit

/// Detects whether the system pasteboard contains a probable web URL, used to prompt recipe imports.
struct PasteboardLinkDetector {

    /// The result of a pasteboard detection check.
    struct Result {
        /// Whether a probable web URL was detected in the pasteboard.
        let shouldShowBanner: Bool
        /// The pasteboard change count at the time of detection.
        let changeCount: Int
    }

    /// Checks the pasteboard for a probable web URL, skipping if the change count hasn't changed.
    /// - Parameter previousChangeCount: The last-seen pasteboard change count.
    /// - Returns: A `Result` indicating whether to show the import banner.
    static func detectProbableWebURL(previousChangeCount: Int) async -> Result {
        let pasteboard = UIPasteboard.general
        let currentCount = pasteboard.changeCount
        
        guard currentCount != previousChangeCount else {
            return Result(shouldShowBanner: false, changeCount: previousChangeCount)
        }
        
        do {
            let matches = try await pasteboard.detectedPatterns(for: [\.probableWebURL])
            return Result(shouldShowBanner: matches.contains(\.probableWebURL), changeCount: currentCount)
        } catch {
            return Result(shouldShowBanner: false, changeCount: currentCount)
        }
    }
}
