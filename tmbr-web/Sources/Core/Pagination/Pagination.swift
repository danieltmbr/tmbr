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

/// Builds a `PageResult<T>` from raw model results.
///
/// Pass `limit + 1` results. This trims to `limit`, detects `hasMore`, and computes
/// `nextCursor` from the last item's date. All list endpoints use this helper.
///
/// - Parameters:
///   - models:     Raw query results (`limit + 1` items).
///   - limit:      The requested page size.
///   - cursorDate: Closure that extracts the sort date from a model (used as the next cursor).
///   - mapping:    Transforms the trimmed `[Model]` into `[T]`.
private let iso8601Formatter = ISO8601DateFormatter()

public func makePage<M: Sendable, T: Codable & Sendable>(
    from models: [M],
    limit: Int,
    cursorDate: (M) -> Date?,
    mapping: ([M]) -> [T]
) -> PageResult<T> {
    let hasMore = models.count > limit
    let items = Array(models.prefix(limit))
    let nextCursor = hasMore ? items.last.flatMap { cursorDate($0) }.map { iso8601Formatter.string(from: $0) } : nil
    return PageResult(items: mapping(items), hasMore: hasMore, nextCursor: nextCursor)
}
