import Foundation
import SwiftData

/// The type of mutation queued for server synchronization.
enum PendingOperationType: String, Codable {
    /// A recipe update (edit name, ingredients, instructions, etc.).
    case updateRecipe
    /// A favorite toggle (add or remove from favorites).
    case toggleFavorite
    /// A new meal plan entry creation.
    case createMealPlan
}

/// A queued mutation awaiting synchronization with the Mealie server.
///
/// When the app is offline or an API call fails, the operation is persisted here
/// and retried when connectivity is restored. Operations are processed in FIFO order
/// by ``SyncManager``.
@Model
final class PendingOperation {

    /// Unique identifier for this operation.
    @Attribute(.unique) var id: String

    /// The type of mutation (stored as a raw string for SwiftData compatibility).
    var operationType: String

    /// The remote ID of the affected entity (recipe or meal plan entry).
    var entityId: String

    /// JSON-encoded payload containing the data needed to replay this operation.
    var payload: Data?

    /// When this operation was first enqueued.
    var createdAt: Date

    /// Number of failed sync attempts so far.
    var retryCount: Int

    /// When the last sync attempt occurred, if any.
    var lastAttempt: Date?

    /// The error message from the most recent failed attempt, if any.
    var errorMessage: String?

    /// Creates a new pending operation.
    init(
        id: String = UUID().uuidString,
        operationType: PendingOperationType,
        entityId: String,
        payload: Data? = nil,
        createdAt: Date = Date(),
        retryCount: Int = 0,
        lastAttempt: Date? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.operationType = operationType.rawValue
        self.entityId = entityId
        self.payload = payload
        self.createdAt = createdAt
        self.retryCount = retryCount
        self.lastAttempt = lastAttempt
        self.errorMessage = errorMessage
    }

    /// The parsed operation type, or `nil` if the raw value is unrecognized.
    var type: PendingOperationType? {
        PendingOperationType(rawValue: operationType)
    }

    /// Maximum number of retry attempts before the operation is considered stale.
    static let maxRetries = 5

    /// Maximum age (in seconds) before an operation is pruned. Defaults to 7 days.
    static let maxAge: TimeInterval = 7 * 24 * 60 * 60
}
