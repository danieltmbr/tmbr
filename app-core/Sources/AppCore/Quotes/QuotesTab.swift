import SwiftUI
import SwiftData
import AppPersistence

struct QuotesTab: View {

    @Query(sort: \QuoteRecord.createdAt, order: .reverse)
    private var allQuotes: [QuoteRecord]

    @Environment(\.refreshCatalogue)
    private var refreshCatalogue

    @Environment(\.refreshBlog)
    private var refreshBlog

    @Catalogue(\.selectedCategorySlugs)
    private var selectedCategorySlugs

    @Preferences(\.selectedLanguages)
    private var selectedLanguages

    @State private var showFilter = false
    @State private var showRandom = false

    private var quotes: [QuoteRecord] {
        var result = allQuotes
        if !selectedCategorySlugs.isEmpty {
            result = result.filter { $0.sourceType.map(selectedCategorySlugs.contains) ?? false }
        }
        if !selectedLanguages.isEmpty {
            result = result.filter { quote in
                guard let lang = quote.language else { return true }
                return selectedLanguages.contains(lang)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(quotes) { quote in
                    QuoteCell(quote: quote)
                }
            }
            .listStyle(.plain)
            .overlay {
                if quotes.isEmpty {
                    QuotesEmptyView()
                }
            }
            .navigationTitle("Quotes")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button { showFilter = true } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { showRandom = true } label: {
                        Image(systemName: "shuffle")
                    }
                }
#else
                ToolbarItem(placement: .automatic) {
                    Button { showFilter = true } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                    .popover(isPresented: $showFilter) {
                        CatalogueFilterView()
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button { showRandom = true } label: {
                        Image(systemName: "shuffle")
                    }
                }
#endif
                ToolbarItem(placement: .primaryAction) {
                    AccountButton()
                }
            }
            .refreshable {
                await refreshCatalogue()
                await refreshBlog()
            }
        }
        .task {
            await refreshCatalogue()
            await refreshBlog()
        }
#if os(iOS)
        .sheet(isPresented: $showFilter) {
            CatalogueFilterView()
        }
#endif
        .sheet(isPresented: $showRandom) {
            RandomQuoteSheet(quotes: allQuotes)
        }
    }
}
