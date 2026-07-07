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
            QuotesList(
                term: searchText.isEmpty ? nil : searchText,
                selectedSources: selectedSources,
                selectedLanguages: selectedLanguages,
                showRandom: $showRandom
            )
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
        // Debounce the network search 300 ms. No refresh on clear — quote browse is
        // populated via catalogue/blog sync, not a standalone quotes refresh.
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

// MARK: - Unified list (browse and search)

private struct QuotesList: View {

    @Query private var quotes: [QuoteRecord]

    @Environment(\.refreshCatalogue)
    private var refreshCatalogue

    @Environment(\.refreshBlog)
    private var refreshBlog

    @Binding private var showRandom: Bool

    let isSearching: Bool

    init(
        term: String?,
        selectedSources: Set<QuoteSourceFilter>,
        selectedLanguages: Set<Language>,
        showRandom: Binding<Bool>
    ) {
        isSearching = term != nil
        _quotes = Query(
            filter: term.map { QuoteRecord.search(term: $0, sources: selectedSources, languages: selectedLanguages) }
                ?? QuoteRecord.list(sources: selectedSources, languages: selectedLanguages),
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
            if isSearching && !quotes.isEmpty {
                QuotesLoadMoreCell()
            }
        }
        .listStyle(.plain)
        .overlay {
            if quotes.isEmpty {
                if isSearching {
                    ContentUnavailableView.search
                } else {
                    QuotesEmptyView()
                }
            }
        }
        .refreshable {
            if !isSearching {
                await refreshCatalogue()
                await refreshBlog()
            }
        }
        .sheet(isPresented: $showRandom) {
            RandomQuoteSheet(quotes: quotes)
        }
    }
}

// MARK: - Load more (search pagination)

private struct QuotesLoadMoreCell: View {

    @Quotes(\.isLoadingMore)
    private var isLoadingMore

    @Quotes(\.hasMore)
    private var hasMore

    @Environment(\.loadQuotes)
    private var loadQuotes

    var body: some View {
        Group {
            if isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                Color.clear.frame(height: 0)
            }
        }
        .listRowSeparator(.hidden)
        .onAppear {
            Task { await loadQuotes() }
        }
    }
}
