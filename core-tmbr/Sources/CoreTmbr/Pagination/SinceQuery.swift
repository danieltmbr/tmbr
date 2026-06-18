import Foundation

/// Query for the deletion-tombstone endpoint — just a delta cursor.
///
/// Tombstones are sparse and unpaginated: the client always asks for everything deleted since the
/// last successful sync.
public struct SinceQuery: Codable, Sendable {

    public let since: Date?

    public init(since: Date? = nil) {
        self.since = since
    }
}
