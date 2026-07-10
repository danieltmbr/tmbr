import Foundation
import TmbrCore

/// What a feed's `Input` must expose for `FeedModel` to drive it — the domain query *is* the
/// paging model: a term makes it a search session, a cursor makes it a continuation, and
/// `page(after:)` points it at the next page. Conforming here is what used to be three
/// injected closures.
public protocol PageableQuery: Sendable {

    /// Whether this query filters by a search term (search session) rather than browsing.
    var isSearch: Bool { get }

    /// The next-page cursor baked into this query, if any — non-nil marks a continuation.
    var cursor: String? { get }

    /// The same query pointed at the next page — cursor replaced, everything else preserved.
    func page(after cursor: String) -> Self
}

extension PostsQuery: PageableQuery {
    public var isSearch: Bool { term != nil }
}

extension QuotesQuery: PageableQuery {
    public var isSearch: Bool { term != nil }
}

extension CatalogueSearchQuery: PageableQuery {
    public var isSearch: Bool { true }      // the endpoint always searches
}

/// The input of the `.catalogue` sync feed — the `SyncGroup` refresh takes no parameters, so
/// this is an empty token: never a search, never paged.
public struct CatalogueSyncQuery: PageableQuery, Hashable {

    public init() {}

    public var isSearch: Bool { false }

    public var cursor: String? { nil }

    public func page(after cursor: String) -> Self { self }
}
