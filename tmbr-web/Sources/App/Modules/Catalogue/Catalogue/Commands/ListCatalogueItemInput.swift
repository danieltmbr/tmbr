import Foundation

/// Shared pagination input for all per-type catalogue list commands.
struct ListCatalogueItemInput: Sendable {
        
    let before: Date?
    
    let limit: Int
    
    let since: Date?

    init(
        before: Date? = nil,
        limit: Int = 50,
        since: Date? = nil
    ) {
        self.before = before
        self.limit = limit
        self.since = since
    }
}
