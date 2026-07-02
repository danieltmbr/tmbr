import Foundation
import Vapor
import TmbrCore

// MARK: - Vapor conformance

// PageResult<T> is Encodable (since T: Codable & Sendable ⊇ Encodable).
// Core's default AsyncResponseEncodable+Encodable impl gives it the
// encodeResponse(for:) implementation — no explicit method body needed.
extension PageResult: @retroactive AsyncResponseEncodable where T: Encodable {}

// MARK: - Cursor decoding

public extension PageQuery {
    /// Decodes the opaque `cursor` string back to a `Date` for use as a `before` filter.
    var cursorDate: Date? {
        guard let cursor else { return nil }
        return ISO8601DateFormatter().date(from: cursor)
    }
}

// MARK: - PageResult builder

private let iso8601Formatter = ISO8601DateFormatter()

public extension PageResult {
    /// Builds a paginated response from raw query results fetched with `limit + 1`.
    /// Trims to `limit`, sets `nextCursor` from the last item's `createdAt` if more exist.
    init<M: Timestamped>(from models: [M], limit: Int, mapping: (M) throws -> T) rethrows {
        let trimmed = Array(models.prefix(limit))
        let nextCursor = models.count > limit
            ? trimmed.last.map { iso8601Formatter.string(from: $0.createdAt) }
            : nil
        self.init(items: try trimmed.map(mapping), nextCursor: nextCursor)
    }
}
