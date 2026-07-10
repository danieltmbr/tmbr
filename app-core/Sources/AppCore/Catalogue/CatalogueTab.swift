import SwiftUI
import SwiftData
import AppPersistence
import TmbrCore

struct CatalogueTab: View {

    @Environment(\.canAuthor)
    private var canAuthor

    @Catalogue(\.selectedCategories)
    private var selectedCategories

    @Preferences(\.selectedLanguages)
    private var selectedLanguages

    @State private var searchText = ""

    @State private var showFilter = false
    
    @State private var showTypePicker = false
    
    @State private var selectedType: CatalogueItemType?
    
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            CatalogueList(
                term: searchText.isEmpty ? nil : searchText,
                selectedCategories: selectedCategories,
                selectedLanguages: selectedLanguages
            )
            .feed(.catalogue)
            .feed(.catalogueSearch)
            .navigationTitle("Catalogue")
            .searchable(text: $searchText, prompt: "Search catalogue…")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button { showFilter = true } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    AuthoringButton(systemImage: "square.and.pencil") { showTypePicker = true }
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
                ToolbarItem(placement: .primaryAction) {
                    AuthoringButton(systemImage: "square.and.pencil") { showTypePicker = true }
                }
#endif
                ToolbarItem(placement: .primaryAction) {
                    AccountButton()
                }
            }
        }
#if os(iOS)
        .sheet(isPresented: $showFilter) {
            CatalogueFilterView()
        }
#endif
        .sheet(isPresented: $showTypePicker) {
            MediaTypePickerSheet { type in
                selectedType = type
            }
        }
        .sheet(isPresented: $showEditor) {
            if let type = selectedType {
                MediaEditorView(type: type)
            }
        }
        .onChange(of: selectedType) { _, type in
            if type != nil { showEditor = true }
        }
    }
}

// MARK: - Unified list

/// A single list view that handles both browse (term == nil) and search (term != nil).
///
/// Browse: `@Query` over `PreviewRecord`s filtered by category + language — auto-reactive to
/// SwiftData upserts; the `.catalogue` feed's refresh (SyncGroup) populates it. Search:
/// `CatalogueSearchEngine.results` (manual fetch) driven by the `.catalogueSearch` feed and the
/// task/onChange handlers below.
private struct CatalogueList: View {

    @Query private var browseItems: [PreviewRecord]

    /// Sync-refresh state for the status line, pull-to-refresh, and the empty view.
    @Feed(CatalogueSyncQuery.self)
    private var browseFeed

    /// Search + paging over `GET /api/catalogue/search`; `refresh()` is never called on it.
    @Feed(CatalogueSearchQuery.self)
    private var searchFeed

    @Environment(\.modelContext)
    private var modelContext

    @State private var searchEngine = CatalogueSearchEngine()

    let term: String?

    private let selectedCategories: Set<CatalogueCategory>

    private let selectedLanguages: Set<Language>

    /// The current search input — term plus active filters; `nil` when not searching.
    /// Also the search `.task` id, so any term or filter change restarts the flow.
    private let searchQuery: CatalogueSearchQuery?

    init(
        term: String?,
        selectedCategories: Set<CatalogueCategory>,
        selectedLanguages: Set<Language>
    ) {
        self.term = term
        self.selectedCategories = selectedCategories
        self.selectedLanguages = selectedLanguages
        searchQuery = term.map {
            CatalogueSearchQuery(
                term: $0,
                types: selectedCategories.apiValues,
                languages: selectedLanguages.apiValues
            )
        }
        _browseItems = Query(
            filter: PreviewRecord.catalogue(categories: selectedCategories, languages: selectedLanguages),
            sort: \PreviewRecord.primaryInfo
        )
    }

    private var isSearching: Bool { term != nil }

    private var hasResults: Bool {
        isSearching ? !searchEngine.results.isEmpty : !browseItems.isEmpty
    }

    var body: some View {
        List {
            if hasResults { FeedStatusLine() }
            if isSearching {
                searchRows
            } else {
                browseRows
            }
        }
        .listStyle(.plain)
        .overlay {
            if isSearching {
                if searchEngine.results.isEmpty { ContentUnavailableView.search }
            } else {
                if browseItems.isEmpty {
                    FeedEmptyView {
                        ContentUnavailableView("Nothing here yet", systemImage: "square.grid.2x2")
                    }
                }
            }
        }
        .navigationDestination(for: CatalogueItemNavigation.self) { CatalogueItemNavigation.destination($0) }
        // Pull-to-refresh restarts page 1 of the current session — sync for browse, the
        // active search otherwise.
        .refreshable {
            if let searchQuery {
                await searchFeed.fetch(searchQuery)
            } else {
                await browseFeed.fetch()
            }
        }
        .task { await browseFeed.fetch() }
        // Flash fix, one task: run local search IMMEDIATELY for instant results, then fire the
        // network fetch (the model supersedes in-flight requests, so the last input wins); a
        // second local search picks up the upserted records. The task id restarts this on any
        // term OR filter change, so the immediate local pass also covers what separate filter
        // onChange handlers would do. On clear, the browse list re-appears automatically via
        // the query predicate.
        .task(id: searchQuery) {
            guard let query = searchQuery else {
                searchEngine.clear()
                return
            }
            let term = query.term
            searchEngine.search(term: term, in: modelContext, categories: selectedCategories, languages: selectedLanguages)
            await searchFeed.fetch(query)
            guard !Task.isCancelled else { return }
            searchEngine.search(term: term, in: modelContext, categories: selectedCategories, languages: selectedLanguages)
        }
        // Re-run local search after a load-more upsert so new records appear immediately.
        // Deliberately NOT part of the task id above: search bumps revision itself, so folding
        // it in would restart the task and loop (search → revision += 1 → restart → search …).
        .onChange(of: searchFeed.state.revision) { _, _ in
            guard let term else { return }
            searchEngine.search(term: term, in: modelContext, categories: selectedCategories, languages: selectedLanguages)
        }
        // Two feeds share this subtree, so the component keys would otherwise follow whichever
        // `.feed(_:)` sits innermost — scope explicitly: status line, empty view, and retry
        // follow the browse (sync) feed; the load-more cell in `searchRows` re-scopes itself
        // to the search feed.
        .feedControls(browseFeed)
    }

    @ViewBuilder
    private var browseRows: some View {
        ForEach(browseItems) { item in
            NavigationLink {
                CatalogueItemDetailView(item: item)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.primaryInfo)
                    if !item.secondaryInfo.isEmpty {
                        Text(item.secondaryInfo)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var searchRows: some View {
        ForEach(searchEngine.results) { result in
            NavigationLink {
                CatalogueItemDetailView(item: result.preview)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.preview.primaryInfo)
                    if let snippet = result.noteSnippet {
                        Text(snippet)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else if !result.preview.secondaryInfo.isEmpty {
                        Text(result.preview.secondaryInfo)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        if !searchEngine.results.isEmpty {
            // Innermost scope wins: this cell pages the search feed, not the browse sync.
            // Row-driven paging (see PostsList) doesn't apply here — engine results aren't
            // createdAt-ordered, so a row's date says nothing about the fetched frontier.
            FeedLoadMoreCell()
                .feedControls(searchFeed)
        }
    }
}
