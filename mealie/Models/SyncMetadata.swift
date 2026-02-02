import Foundation
import SwiftData

/// Persistent key-value store for synchronization metadata.
///
/// Uses a unique `key` string to store typed values. Currently supports
/// date values via ``dateValue``, used to persist the last successful sync time.
@Model
final class SyncMetadata {

    /// The unique key identifying this metadata entry.
    @Attribute(.unique) var key: String

    /// A date value associated with this key.
    var dateValue: Date?

    /// Creates a metadata entry with a key and optional date value.
    init(key: String, dateValue: Date? = nil) {
        self.key = key
        self.dateValue = dateValue
    }

    // MARK: - Convenience Accessors

    /// The key used to store the last successful sync timestamp.
    static let lastSyncTimeKey = "lastSyncTime"

    /// Retrieves the last successful sync time from the persistent store.
    /// - Parameter context: The SwiftData model context to query.
    /// - Returns: The last sync time, or `nil` if no sync has occurred.
    static func lastSyncTime(in context: ModelContext) -> Date? {
        let key = lastSyncTimeKey
        let descriptor = FetchDescriptor<SyncMetadata>(
            predicate: #Predicate { $0.key == key }
        )
        return (try? context.fetch(descriptor))?.first?.dateValue
    }

    /// Persists the last successful sync time.
    /// - Parameters:
    ///   - date: The sync completion timestamp.
    ///   - context: The SwiftData model context to write to.
    static func setLastSyncTime(_ date: Date, in context: ModelContext) {
        let key = lastSyncTimeKey
        let descriptor = FetchDescriptor<SyncMetadata>(
            predicate: #Predicate { $0.key == key }
        )
        if let existing = (try? context.fetch(descriptor))?.first {
            existing.dateValue = date
        } else {
            context.insert(SyncMetadata(key: key, dateValue: date))
        }
        try? context.save()
    }
}
