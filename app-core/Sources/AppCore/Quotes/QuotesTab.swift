import SwiftUI
import SwiftData
import AppPersistence
import TmbrCore

struct QuotesTab: View {

    @Environment(\.refreshCatalogue)
    private var refreshCatalogue

    @Environment(\.refreshBlog)
    private var refreshBlog

    @Environment(\.searchQuotes)
    private var searchQuotes

    @Quotes(\.selectedSources)
    private var selectedSources

    @Preferences(\.selectedLanguages)
    private var selectedLanguages

    @State private var searchText = ""
    @State private var showFilter = false
    @State private var showRandom = false

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    QuotesList(
                        selectedSources: selectedSources,
                        selectedLanguages: selectedLanguages,
                        showRandom: $showRandom
                    )
                } else {
                    QuotesSearchList(
                        term: searchText,
                        selectedSources: selectedSources,
                        selectedLanguages: selectedLanguages
                    )
                }
            }
            .navigationTitle("Quotes")
            .searchable(text: $searchText, prompt: "Search quotes…")
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
        // Fire network search on term changes (debounced 300 ms).
        .task(id: searchText) {
            guard !searchText.isEmpty else { return }
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await searchQuotes(term: searchText)
        }
#if os(iOS)
        .sheet(isPresented: $showFilter) {
            QuotesFilterView()
        }
#endif
    }
}

// MARK: - Browse list (no search term)

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

// MARK: - Search list (active search term)

private struct QuotesSearchList: View {

    @Query private var quotes: [QuoteRecord]

    init(term: String, selectedSources: Set<QuoteSourceFilter>, selectedLanguages: Set<Language>) {
        _quotes = Query(
            filter: QuoteRecord.search(term: term, sources: selectedSources, languages: selectedLanguages),
            sort: \QuoteRecord.createdAt,
            order: .reverse
        )
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
                ContentUnavailableView.search
            }
        }
    }
}
