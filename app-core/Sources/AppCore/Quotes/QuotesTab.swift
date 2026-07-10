import SwiftUI
import SwiftData
import AppPersistence
import TmbrCore

struct QuotesTab: View {

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
                languages: selectedLanguages,
                sources: selectedSources,
                searchText: searchText,
                showRandom: $showRandom
            )
            .feed(.quotes)
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
#if os(iOS)
        .sheet(isPresented: $showFilter) {
            QuotesFilterView()
        }
#endif
    }
}

// MARK: - Unified list (browse and search)

private struct QuotesList: View {

    @Feed(QuotesQuery.self)
    private var feed

    /// The view's paging state — the source of truth for what to fetch next. Reset on every
    /// new intent, updated from the receipt of each committed fetch.
    @State
    private var page: FeedPage?

    @Query
    private var quotes: [QuoteRecord]

    @Binding
    private var showRandom: Bool

    private let languages: Set<Language>

    private let sources: Set<QuoteSourceFilter>

    private let searchText: String

    init(
        languages: Set<Language>,
        sources: Set<QuoteSourceFilter>,
        searchText: String,
        showRandom: Binding<Bool>
    ) {
        self.languages = languages
        self.sources = sources
        self.searchText = searchText
        _showRandom = showRandom
        _quotes = Query(
            filter: QuoteRecord.quotes(term: searchText, sources: sources, languages: languages),
            sort: \QuoteRecord.createdAt,
            order: .reverse
        )
    }

    var body: some View {
        List {
            ForEach(quotes) { quote in
                QuoteCell(quote: quote)
                    .onAppear { [createdAt = quote.createdAt] in
                        Task { await fetch(after: createdAt) }
                    }
            }
            if !quotes.isEmpty {
                FeedLoadMoreCell()
            }
        }
        .listStyle(.plain)
        .overlay {
            if quotes.isEmpty {
                FeedEmptyView {
                    ContentUnavailableView("Nothing here yet", systemImage: "quote.bubble")
                }
            }
        }
        .refreshable {
            await fetch(page: nil)
        }
        // Runs on appear and restarts on any term or filter change (the id is the page-1
        // query) — the model supersedes in-flight requests, so the last input wins.
        .task(id: query()) {
            await fetch(page: nil)
        }
        .sheet(isPresented: $showRandom) {
            RandomQuoteSheet(quotes: quotes)
        }
    }

    /// Fetches for the given paging state — `nil` is page 1 — and folds the receipt back in.
    /// The `?? page` fallback is the failure policy: a failed page 1 falls back to `nil`
    /// (no dead sessions), while a failed next page falls back to its own pre-call state,
    /// so a later row appearance retries it.
    private func fetch(page: FeedPage?) async {
        self.page = await feed.fetch(query(page: page)) ?? page
    }

    /// Row-driven paging: a row at or past the fetched frontier is unverified local cache —
    /// fetch the next page for it. The `nextCursor` check gates exhaustion: without it, an
    /// exhausted page would build a cursor-less query and restart the session as page 1.
    private func fetch(after createdAt: Date) async {
        guard let page, page.nextCursor != nil,
              let frontier = page.frontier,
              createdAt <= frontier else { return }
        await fetch(page: page)
    }

    private func query(page: FeedPage? = nil) -> QuotesQuery {
        QuotesQuery(
            cursor: page?.nextCursor,
            languages: languages,
            sources: sources.apiValues,
            term: searchText
        )
    }
}
