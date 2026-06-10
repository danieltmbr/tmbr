import Foundation

/// Query parameters for any paginated list endpoint.
///
/// - `since`: delta-sync cursor — returns items created *after* this date (forward in time).
/// - `cursor`: load-more cursor — the opaque `nextCursor` value from the previous `Page` response,
///   used to fetch the next page of older items (backward in time).
/// - `limit`: maximum items per page (server default: 50, server max: 100).
public struct PageQuery: Codable, Sendable {

    public let since: Date?

    public let cursor: String?

    public let limit: Int?

    public init(since: Date? = nil, cursor: String? = nil, limit: Int? = nil) {
        self.since = since
        self.cursor = cursor
        self.limit = limit
    }
}
