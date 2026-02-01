import Foundation

/// Reusable ISO8601 formatter configured to handle fractional seconds.
/// Allocated once at launch for efficiency.
private let isoFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

/// Fallback ISO8601 formatter for timestamps that omit fractional seconds.
private let isoFormatterNoFractional: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

/// Parses a date string from the Mealie API, trying ISO8601 (with and without fractional seconds)
/// and falling back to date-only format (`yyyy-MM-dd`). Returns `nil` if all formats fail.
func parseAPIDate(_ dateString: String?) -> Date? {
    guard let dateString = dateString, !dateString.isEmpty else { return nil }
    
    // Try the robust ISO8601 formatter first.
    // It's configured to handle timestamps with fractional seconds and various timezone formats.
    if let date = isoFormatter.date(from: dateString) {
        return date
    }
    
    // Some endpoints omit fractional seconds; fall back to a formatter that allows that format.
    if let date = isoFormatterNoFractional.date(from: dateString) {
        return date
    }
    
    // Fallback for date-only strings like "yyyy-MM-dd"
    let dateOnlyFormatter = DateFormatter()
    dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
    if let date = dateOnlyFormatter.date(from: dateString) {
        return date
    }

    // It's useful to know if parsing fails for an unexpected format
    AppLogger.warning(.general, "Could not parse date: \(dateString)")
    return nil
}

/// Parses a date string for sorting, returning `.distantPast` if parsing fails.
func parseAPIDateForSort(_ dateString: String?) -> Date {
    return parseAPIDate(dateString) ?? .distantPast
} 

/// This is a simple helper to format the date with UTC timezone and start of the day to remove the time.
/// Mealie API requires some dates to be in this format.
func getDateStringForAPI(_ date: Date) -> String {
    
    var utcCalendar = Calendar.current
    utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let startOfUTCToday = utcCalendar.startOfDay(for: date)
    let currentDateString = isoFormatter.string(from: startOfUTCToday)
    return currentDateString
    
}
