import Foundation

/// Tracks whether a local record needs to be pushed to the backend.
///
/// Stored as a `String` rawValue in each @Model record so SwiftData
/// can persist it without a separate migration when cases are added.
enum SyncState: String, Codable {
    /// Matches the server state exactly.
    case synced
    /// Exists locally, not yet on the server.
    case pendingCreate
    /// Local version differs from the server's.
    case pendingUpdate
    /// Deleted locally; server delete is pending.
    case pendingDelete
}
