import Foundation

/// Query parameters for any paginated list endpoint.
///
/// - `since`: delta-sync cursor — returns items created *after* this date (forward in time).
/// - `cursor`: load-more cursor — the opaque `nextCursor` value from the previous `Page` response,
///   used to fetch the next page of older items (backward in time).
/// - `limit`: maximum items per page (server default: 50, server max: 100).
///
public struct PageQuery: Codable, Sendable {

    public let since: Date?

    public let cursor: String?

    public let limit: Int

    public init(
        since: Date? = nil,
        cursor: String? = nil,
        limit: Int = 50
    ) {
        self.since = since
        self.cursor = cursor
        self.limit = limit
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.since = try container.decodeIfPresent(Date.self, forKey: .since)
        self.cursor = try container.decodeIfPresent(String.self, forKey: .cursor)
        self.limit = try container.decodeIfPresent(Int.self, forKey: .limit) ?? 50
    }
}
