import Foundation

/// Query parameters for any paginated list endpoint.
///
/// - `since`: delta-sync cursor — returns items created *after* this date (forward in time).
/// - `cursor`: load-more cursor — the opaque `nextCursor` value from the previous `PageResult`
///   response, used to fetch the next page of older items (backward in time).
/// - `limit`: maximum items per page (server default: 50, server max: 100).
///
/// The custom `encode(to:)` implementation ensures `since` is always encoded as an
/// ISO 8601 string. The default synthesised encoder would produce a `Double` timestamp,
/// which Vapor's `URLQueryDecoder` does not accept for `Date` query parameters.
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

    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case since, cursor, limit
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let since {
            try container.encode(ISO8601DateFormatter().string(from: since), forKey: .since)
        }
        try container.encodeIfPresent(cursor, forKey: .cursor)
        try container.encode(limit, forKey: .limit)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Decode `since` as String (ISO 8601) when coming from URL query params,
        // or as Date when coming from JSON body — try both.
        if let sinceString = try? container.decodeIfPresent(String.self, forKey: .since) {
            since = ISO8601DateFormatter().date(from: sinceString)
        } else {
            since = try container.decodeIfPresent(Date.self, forKey: .since)
        }
        cursor = try container.decodeIfPresent(String.self, forKey: .cursor)
        limit = try container.decodeIfPresent(Int.self, forKey: .limit) ?? 50
    }
}
