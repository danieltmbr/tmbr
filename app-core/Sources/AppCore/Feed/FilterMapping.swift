import Foundation
import TmbrCore
import AppPersistence

// The tab views translate their filter selections into API query parameter values when
// constructing feed inputs (`PostsQuery`, `QuotesQuery`, `CatalogueSearchQuery`).

extension Set where Element == Language {
    /// Language codes for API query parameters; `nil` when no filter is active.
    var apiValues: [String]? {
        isEmpty ? nil : map(\.rawValue).sorted()
    }
}

extension Set where Element == QuoteSourceFilter {
    /// Source buckets for API query parameters — category slugs plus the `blog_posts`
    /// sentinel; `nil` when no filter is active.
    var apiValues: [String]? {
        guard !isEmpty else { return nil }
        return map { source in
            switch source {
            case .category(let category): category.slug
            case .blogPosts: "blog_posts"
            }
        }.sorted()
    }
}

extension Set where Element == CatalogueCategory {
    /// Category slugs for API query parameters; `nil` when no filter is active.
    var apiValues: [String]? {
        isEmpty ? nil : map(\.slug).sorted()
    }
}
