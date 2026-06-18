import Foundation

/// `PageQuery` plus `notes=true` — the orphans endpoint embeds each orphan's notes only when asked.
///
/// Same cursor semantics as `PageQuery` (`since` for delta sync, `cursor` for load-more), with an
/// extra `notes` flag the backend uses to decide whether to inline `PreviewResponse.notes`.
public struct OrphanPageQuery: Codable, Sendable {

    public let since: Date?

    public let cursor: String?

    public let limit: Int

    public let notes: Bool

    public init(
        since: Date? = nil,
        cursor: String? = nil,
        limit: Int = 50,
        notes: Bool = true
    ) {
        self.since = since
        self.cursor = cursor
        self.limit = limit
        self.notes = notes
    }
}
