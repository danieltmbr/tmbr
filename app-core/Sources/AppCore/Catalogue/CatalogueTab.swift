import SwiftUI
import SwiftData
import AppPersistence
import TmbrCore

struct CatalogueTab: View {

    @Environment(\.refreshCatalogue)
    private var refreshCatalogue

    @Environment(\.searchCatalogue)
    private var searchCatalogue

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.canAuthor)
    private var canAuthor

    @Catalogue(\.selectedCategories)
    private var selectedCategories

    @Catalogue(\.loadMoreRevision)
    private var loadMoreRevision

    @Preferences(\.selectedLanguages)
    private var selectedLanguages

    @State private var searchText = ""
    @State private var searchEngine = CatalogueSearchEngine()

    @State private var showFilter = false
    @State private var showTypePicker = false
    @State private var selectedType: CatalogueItemType?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            CatalogueList(
                term: searchText.isEmpty ? nil : searchText,
                selectedCategories: selectedCategories,
                selectedLanguages: selectedLanguages,
                engine: searchEngine
            )
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
        .task { await refreshCatalogue() }
        // Flash fix: run local search IMMEDIATELY for instant results, then debounce the
        // network call (300 ms). A second local search after the network call picks up upserted
        // records. On clear, the browse list re-appears automatically via the query predicate.
        .task(id: searchText) {
            guard !searchText.isEmpty else {
                searchEngine.clear()
                return
            }
            let term = searchText
            searchEngine.search(term: term, in: modelContext, categories: selectedCategories, languages: selectedLanguages)
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await searchCatalogue(term: term)
            guard !Task.isCancelled else { return }
            searchEngine.search(term: term, in: modelContext, categories: selectedCategories, languages: selectedLanguages)
        }
        // Re-run local search if filters change while search is active.
        .onChange(of: selectedCategories) { _, categories in
            guard !searchText.isEmpty else { return }
            searchEngine.search(term: searchText, in: modelContext, categories: categories, languages: selectedLanguages)
        }
        .onChange(of: selectedLanguages) { _, languages in
            guard !searchText.isEmpty else { return }
            searchEngine.search(term: searchText, in: modelContext, categories: selectedCategories, languages: languages)
        }
        // Re-run local search after a load-more upsert so new records appear immediately.
        .onChange(of: loadMoreRevision) { _, _ in
            guard !searchText.isEmpty else { return }
            searchEngine.search(term: searchText, in: modelContext, categories: selectedCategories, languages: selectedLanguages)
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
/// SwiftData upserts. Search: `CatalogueSearchEngine.results` (manual fetch, driven by the
/// parent tab's `.task(id: searchText)` and `.onChange(of: loadMoreRevision)` handlers).
private struct CatalogueList: View {

    @Query private var browseItems: [PreviewRecord]

    @Environment(\.refreshCatalogue)
    private var refreshCatalogue

    let term: String?
    let engine: CatalogueSearchEngine

    init(
        term: String?,
        selectedCategories: Set<CatalogueCategory>,
        selectedLanguages: Set<Language>,
        engine: CatalogueSearchEngine
    ) {
        self.term = term
        self.engine = engine
        _browseItems = Query(
            filter: PreviewRecord.catalogue(categories: selectedCategories, languages: selectedLanguages),
            sort: \PreviewRecord.primaryInfo
        )
    }

    private var isSearching: Bool { term != nil }

    private var hasResults: Bool {
        isSearching ? !engine.results.isEmpty : !browseItems.isEmpty
    }

    var body: some View {
        List {
            if hasResults { CatalogueStatusLine() }
            if isSearching {
                searchRows
            } else {
                browseRows
            }
        }
        .listStyle(.plain)
        .overlay {
            if isSearching {
                if engine.results.isEmpty { ContentUnavailableView.search }
            } else {
                if browseItems.isEmpty { CatalogueEmptyView() }
            }
        }
        .navigationDestination(for: CatalogueItemNavigation.self) { CatalogueItemNavigation.destination($0) }
        .refreshable {
            if !isSearching { await refreshCatalogue() }
        }
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
        ForEach(engine.results) { result in
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
        if !engine.results.isEmpty {
            CatalogueLoadMoreCell()
        }
    }
}

// MARK: - Load more (search pagination)

private struct CatalogueLoadMoreCell: View {

    @Catalogue(\.isLoadingMore)
    private var isLoadingMore

    @Catalogue(\.hasMore)
    private var hasMore

    @Environment(\.loadCatalogue)
    private var loadCatalogue

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
            Task { await loadCatalogue() }
        }
    }
}
