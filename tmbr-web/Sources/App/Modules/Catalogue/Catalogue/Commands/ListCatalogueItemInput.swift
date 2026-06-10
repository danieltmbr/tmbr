import Foundation

/// Shared pagination input for all per-type catalogue list commands.
struct ListCatalogueItemInput: Sendable {
    let ownerID: Int
    let since: Date?
    let before: Date?
    let limit: Int

    init(ownerID: Int, since: Date? = nil, before: Date? = nil, limit: Int = 50) {
        self.ownerID = ownerID
        self.since = since
        self.before = before
        self.limit = limit
    }
}
