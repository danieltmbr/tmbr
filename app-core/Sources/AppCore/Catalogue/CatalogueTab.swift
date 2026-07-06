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
            Group {
                if searchText.isEmpty {
                    CatalogueItemsList(
                        selectedCategories: selectedCategories,
                        selectedLanguages: selectedLanguages
                    )
                } else {
                    CatalogueSearchList(engine: searchEngine)
                }
            }
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
        // Fire local search immediately, then network search, then re-run local (sees new upserts).
        .task(id: searchText) {
            guard !searchText.isEmpty else {
                searchEngine.clear()
                return
            }
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            let term = searchText
            searchEngine.search(term: term, in: modelContext, categories: selectedCategories, languages: selectedLanguages)
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

// MARK: - Browse list (no search term)

private struct CatalogueItemsList: View {

    @Query private var items: [PreviewRecord]

    @Environment(\.refreshCatalogue)
    private var refreshCatalogue

    init(selectedCategories: Set<CatalogueCategory>, selectedLanguages: Set<Language>) {
        _items = Query(
            filter: PreviewRecord.catalogue(categories: selectedCategories, languages: selectedLanguages),
            sort: \PreviewRecord.primaryInfo
        )
    }

    var body: some View {
        List {
            if !items.isEmpty {
                CatalogueStatusLine()
            }
            ForEach(items) { item in
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
        .overlay {
            if items.isEmpty {
                CatalogueEmptyView()
            }
        }
        .navigationDestination(for: CatalogueItemNavigation.self) { CatalogueItemNavigation.destination($0) }
        .refreshable { await refreshCatalogue() }
    }
}

// MARK: - Search list (active search term, driven by CatalogueSearchEngine)

private struct CatalogueSearchList: View {

    let engine: CatalogueSearchEngine

    var body: some View {
        List {
            ForEach(engine.results) { result in
                NavigationLink {
                    CatalogueItemDetailView(item: result.preview)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.preview.primaryInfo)
                        if let snippet = result.noteSnippet {
                            // Note-body match: show a snippet of the matched note.
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
        }
        .overlay {
            if engine.results.isEmpty {
                ContentUnavailableView.search
            }
        }
        .navigationDestination(for: CatalogueItemNavigation.self) { CatalogueItemNavigation.destination($0) }
    }
}
