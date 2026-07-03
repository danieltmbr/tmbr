import SwiftUI
import SwiftData
import AppPersistence

/// Adaptively shows "Select All" or "Deselect All" based on whether every source bucket —
/// catalogue categories plus the blog-posts sentinel — is currently selected.
/// Uses `.override` strategy so it replaces the selection in one tap.
struct QuoteSelectAllButton: View {

    @Query
    private var allCategories: [CatalogueCategoryRecord]

    private var categories: [CatalogueCategoryRecord] {
        allCategories.filter { $0.kind != .virtual && $0.kind != .promotable }
    }

    @Quotes(\.selectedSources)
    private var selectedSources

    @Environment(\.selectQuoteSources)
    private var selectQuoteSources

    /// The full universe of selectable buckets: every category slug + the blog-posts sentinel.
    private var allBuckets: Set<String> {
        Set(categories.map(\.slug)).union([QuotesModel.blogPosts])
    }

    private var allSelected: Bool {
        !allBuckets.isEmpty && allBuckets.isSubset(of: selectedSources)
    }

    var body: some View {
        Button(allSelected ? "Deselect All" : "Select All") {
            selectQuoteSources(allSelected ? [] : allBuckets, strategy: .override)
        }
    }
}
