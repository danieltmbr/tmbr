import SwiftUI
import SwiftData
import AppPersistence
import TmbrCore

/// Scope for the dedicated Search tab's segmented scope bar.
enum SearchScope: String, CaseIterable {
    case all = "All"
    case blog = "Blog"
    case catalogue = "Catalogue"
    case quotes = "Quotes"
}

public struct SearchTab: View {

    @Environment(\.searchBlog)
    private var searchBlog

    @Environment(\.searchCatalogue)
    private var searchCatalogue

    @Environment(\.searchQuotes)
    private var searchQuotes

    @Environment(\.modelContext)
    private var modelContext

    @Preferences(\.selectedLanguages)
    private var selectedLanguages

    @Catalogue(\.selectedCategories)
    private var selectedCategories

    @Quotes(\.selectedSources)
    private var selectedSources

    @State private var searchText = ""
    @State private var selectedScope: SearchScope = .all
    @State private var catalogueEngine = CatalogueSearchEngine()

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "Search",
                        systemImage: "magnifyingglass",
                        description: Text("Posts, songs, books, movies, and more.")
                    )
                } else {
                    SearchResultsView(
                        term: searchText,
                        scope: selectedScope,
                        catalogueEngine: catalogueEngine,
                        selectedLanguages: selectedLanguages,
                        selectedCategories: selectedCategories,
                        selectedSources: selectedSources
                    )
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Posts, songs, books…")
            .searchScopes($selectedScope, activation: .onSearchPresentation) {
                ForEach(SearchScope.allCases, id: \.self) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            .navigationDestination(for: PostRecord.self) { post in
                PostReaderView(
                    title: post.title,
                    content: post.content,
                    created: post.createdAt,
                    published: post.publishedAt
                )
            }
            .navigationDestination(for: CatalogueItemNavigation.self) { CatalogueItemNavigation.destination($0) }
        }
        // Fire all network searches in parallel when term changes (debounced 300 ms).
        .task(id: searchText) {
            guard !searchText.isEmpty else {
                catalogueEngine.clear()
                return
            }
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            let term = searchText
            // Local catalogue search runs immediately.
            catalogueEngine.search(term: term, in: modelContext, categories: selectedCategories, languages: selectedLanguages)
            // All three network searches fire concurrently.
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await searchBlog(term: term) }
                group.addTask { await searchCatalogue(term: term) }
                group.addTask { await searchQuotes(term: term) }
            }
            guard !Task.isCancelled else { return }
            // Re-run local catalogue search to pick up newly upserted items/notes.
            catalogueEngine.search(term: term, in: modelContext, categories: selectedCategories, languages: selectedLanguages)
        }
    }
}

// MARK: - Results view (switches on scope)

private struct SearchResultsView: View {

    let term: String
    let scope: SearchScope
    let catalogueEngine: CatalogueSearchEngine
    let selectedLanguages: Set<Language>
    let selectedCategories: Set<CatalogueCategory>
    let selectedSources: Set<QuoteSourceFilter>

    var body: some View {
        List {
            switch scope {
            case .all:
                PostsSection(term: term, selectedLanguages: selectedLanguages)
                CatalogueSection(engine: catalogueEngine)
                QuotesSection(term: term, selectedSources: selectedSources, selectedLanguages: selectedLanguages)
            case .blog:
                PostsSection(term: term, selectedLanguages: selectedLanguages)
            case .catalogue:
                CatalogueSection(engine: catalogueEngine)
            case .quotes:
                QuotesSection(term: term, selectedSources: selectedSources, selectedLanguages: selectedLanguages)
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Blog section

private struct PostsSection: View {

    @Query private var posts: [PostRecord]

    init(term: String, selectedLanguages: Set<Language>) {
        _posts = Query(
            filter: PostRecord.search(term: term, languages: selectedLanguages),
            sort: \PostRecord.createdAt,
            order: .reverse
        )
    }

    var body: some View {
        if !posts.isEmpty {
            Section("Blog") {
                ForEach(posts) { post in
                    NavigationLink(value: post) {
                        PostCell(
                            title: post.title,
                            date: post.publishedAt ?? post.createdAt
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Catalogue section

private struct CatalogueSection: View {

    let engine: CatalogueSearchEngine

    var body: some View {
        if !engine.results.isEmpty {
            Section("Catalogue") {
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
            }
        }
    }
}

// MARK: - Quotes section

private struct QuotesSection: View {

    @Query private var quotes: [QuoteRecord]

    init(term: String, selectedSources: Set<QuoteSourceFilter>, selectedLanguages: Set<Language>) {
        _quotes = Query(
            filter: QuoteRecord.search(term: term, sources: selectedSources, languages: selectedLanguages),
            sort: \QuoteRecord.createdAt,
            order: .reverse
        )
    }

    var body: some View {
        if !quotes.isEmpty {
            Section("Quotes") {
                ForEach(quotes) { quote in
                    QuoteCell(quote: quote)
                }
            }
        }
    }
}
