import Foundation
import TmbrCore

/// A cursor-paginated query the `syncAll` driver can re-issue page after page.
///
/// Unifies `PageQuery` and `OrphanPageQuery` so a single driver walks either to completion.
public protocol CursorQuery: Encodable & Sendable {
    init(since: Date?, cursor: String?, limit: Int)
}

extension PageQuery: CursorQuery {}

extension OrphanPageQuery: CursorQuery {
    public init(since: Date?, cursor: String?, limit: Int) {
        self.init(since: since, cursor: cursor, limit: limit, notes: true)
    }
}

public extension RequestLoader where Input: CursorQuery {

    /// Drives a paginated endpoint to completion.
    ///
    /// Sends `since` on the **first** page only, then follows `nextCursor` (older pages) until the
    /// server returns `nil`.
    func syncAll<T>(since: Date?, limit: Int = 50) async throws -> [T] where Response == PageResult<T> {
        var all: [T] = []
        var cursor: String?
        repeat {
            let query = Input(since: all.isEmpty ? since : nil, cursor: cursor, limit: limit)
            let page = try await load(from: query)
            all.append(contentsOf: page.items)
            cursor = page.nextCursor
        } while cursor != nil
        return all
    }
}
