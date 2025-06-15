import Foundation

extension DateFormatter {
    static let mealieDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
} 