import Foundation

// A reusable formatter for ISO8601 dates, configured to handle fractional seconds.
// This is more efficient than creating a new formatter on each call.
private let isoFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

// A helper to parse various date formats from the API
func parseAPIDate(_ dateString: String?) -> Date? {
    guard let dateString = dateString, !dateString.isEmpty else { return nil }
    
    // Try the robust ISO8601 formatter first.
    // It's configured to handle timestamps with fractional seconds and various timezone formats.
    if let date = isoFormatter.date(from: dateString) {
        return date
    }
    
    // Fallback for date-only strings like "yyyy-MM-dd"
    let dateOnlyFormatter = DateFormatter()
    dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
    if let date = dateOnlyFormatter.date(from: dateString) {
        return date
    }

    // It's useful to know if parsing fails for an unexpected format
    print("⚠️ Could not parse date: \(dateString)")
    return nil
}

// A version for SwiftUI views that need a non-optional Date for sorting
func parseAPIDateForSort(_ dateString: String?) -> Date {
    return parseAPIDate(dateString) ?? .distantPast
} 