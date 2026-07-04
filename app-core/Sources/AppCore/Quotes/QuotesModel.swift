import Foundation
import AppPersistence

/// Headless model for the Quotes tab — tracks the active source filter.
///
/// `selectedSources` is a unified set of **source buckets**: catalogue category slugs
/// (for note-sourced quotes) plus `.blogPosts` (for post-sourced quotes).
/// Empty = no filter (show all).
///
/// This is intentionally decoupled from `CatalogueModel` — the Quotes filter is a
/// superset of catalogue categories (it also spans blog posts), so the two tabs maintain
/// independent selections.
@MainActor
@Observable
public final class QuotesModel {

    /// Source buckets currently active in the filter. Empty = no filter (show all).
    public var selectedSources: Set<QuoteSourceFilter> = []

    public init() {}
}
