import Foundation

/// A typed source bucket for the Quotes filter.
///
/// Replaces the raw-`String` selection that mixed category slugs with the
/// `"__blog_posts__"` sentinel. The `.category` case wraps an opaque
/// `CatalogueCategory` — instances can only be obtained from a real
/// `CatalogueCategoryRecord`, so the filter cannot be set to an arbitrary value.
public enum QuoteSourceFilter: Hashable, Sendable {
    /// Quotes sourced from a note attached to a catalogue item of this category.
    case category(CatalogueCategory)
    /// Quotes sourced from a blog post.
    case blogPosts
}
