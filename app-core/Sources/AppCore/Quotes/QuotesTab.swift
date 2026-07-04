import SwiftUI
import SwiftData
import AppPersistence

struct QuotesTab: View {

    @Environment(\.refreshCatalogue)
    private var refreshCatalogue

    @Environment(\.refreshBlog)
    private var refreshBlog

    @Quotes(\.selectedSources)
    private var selectedSources

    @Preferences(\.selectedLanguages)
    private var selectedLanguages

    @State private var showFilter = false
    @State private var showRandom = false

    var body: some View {
        NavigationStack {
            QuotesList(
                selectedSources: selectedSources,
                selectedLanguages: selectedLanguages,
                showRandom: $showRandom
            )
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
                        QuotesFilterView()
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
        }
        .task {
            await refreshCatalogue()
            await refreshBlog()
        }
#if os(iOS)
        .sheet(isPresented: $showFilter) {
            QuotesFilterView()
        }
#endif
    }
}

private struct QuotesList: View {

    @Query private var quotes: [QuoteRecord]

    @Environment(\.refreshCatalogue)
    private var refreshCatalogue

    @Environment(\.refreshBlog)
    private var refreshBlog

    @Binding private var showRandom: Bool

    init(selectedSources: Set<QuoteSourceFilter>, selectedLanguages: Set<Language>, showRandom: Binding<Bool>) {
        _quotes = Query(
            filter: QuoteRecord.list(sources: selectedSources, languages: selectedLanguages),
            sort: \QuoteRecord.createdAt,
            order: .reverse
        )
        _showRandom = showRandom
    }

    var body: some View {
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
        .refreshable {
            await refreshCatalogue()
            await refreshBlog()
        }
        .sheet(isPresented: $showRandom) {
            RandomQuoteSheet(quotes: quotes)
        }
    }
}
