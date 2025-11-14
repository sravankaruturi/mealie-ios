import UIKit

struct PasteboardLinkDetector {
    
    struct Result {
        let shouldShowBanner: Bool
        let changeCount: Int
    }
    
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
