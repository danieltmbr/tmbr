import Foundation

/// Headless model for the Quotes tab — tracks the active source filter.
///
/// `selectedSources` is a unified set of **source buckets**: catalogue category slugs
/// (for note-sourced quotes) plus `QuotesModel.blogPosts` (for post-sourced quotes).
/// Empty = no filter (show all).
///
/// This is intentionally decoupled from `CatalogueModel` — the Quotes filter is a
/// superset of catalogue categories (it also spans blog posts), so the two tabs maintain
/// independent selections.
@MainActor
@Observable
public final class QuotesModel {

    /// Sentinel bucket ID for quotes that originate from a blog post (no catalogue category).
    /// Guaranteed not to collide with real category slugs because slugs are short plain words.
    public static let blogPosts = "__blog_posts__"

    /// Bucket IDs currently active in the filter. Empty = no filter (show all).
    public var selectedSources: Set<String> = []

    public init() {}
}
