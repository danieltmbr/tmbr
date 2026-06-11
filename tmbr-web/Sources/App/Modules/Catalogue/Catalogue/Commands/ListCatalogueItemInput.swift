import Foundation

/// Shared pagination input for all per-type catalogue list commands.
struct ListCatalogueItemInput: Sendable {
    let since: Date?
    let before: Date?
    let limit: Int

    init(since: Date? = nil, before: Date? = nil, limit: Int = 50) {
        self.since = since
        self.before = before
        self.limit = limit
    }
}
