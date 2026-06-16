import Foundation

/// Tracks whether a local record needs to be pushed to the backend.
///
/// Stored as a `String` rawValue in each `@Model` record so SwiftData can persist it without a
/// migration when cases are added. Used fully by the Author app, set-but-ignored by Personal
/// (CloudKit mirrors), and effectively always `.synced` in the read-only Reader app.
/// 
public enum SyncState: String, Codable, Sendable {
    
    /// Matches the server state exactly.
    case synced
    
    /// Exists locally, not yet on the server.
    case pendingCreate
    
    /// Local version differs from the server's.
    case pendingUpdate
    
    /// Deleted locally; server delete is pending.
    case pendingDelete
}
