import Foundation

extension DateFormatter {
    /// A medium-style date formatter (e.g., "Jan 1, 2025") used for displaying dates in the UI.
    static let mealieDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
} 