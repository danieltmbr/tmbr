import SwiftUI
import SwiftData
import AppPersistence

/// The "Sources" filter section for the Quotes filter sheet.
///
/// Lists every filterable catalogue category (excluding virtual groupings and promotable
/// placeholders) followed by a "Blog posts" row for post-sourced quotes. The section header
/// carries a contextual `QuoteSelectAllButton` so the button is clearly scoped to sources only.
struct QuoteSourcesSection: View {

    @Query(sort: \CatalogueCategoryRecord.name)
    private var allCategories: [CatalogueCategoryRecord]

    private var categories: [CatalogueCategoryRecord] {
        allCategories.filter { $0.kind != .virtual && $0.kind != .promotable }
    }

    var body: some View {
        Section {
            QuoteFilterRow(
                source: .blogPosts,
                name: "Blog posts",
                systemImage: "text.page"
            )
            .listRowBackground(Color.clear)
            ForEach(categories) { category in
                QuoteFilterRow(
                    source: .category(category.categorySlug),
                    name: category.name,
                    systemImage: category.icon ?? "link"
                )
                .listRowBackground(Color.clear)
            }
        } header: {
            HStack {
                Text("Sources")
                Spacer()
                QuoteSelectAllButton()
            }
        }
    }
}
