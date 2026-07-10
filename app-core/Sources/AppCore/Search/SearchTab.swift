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

    @Preferences(\.selectedLanguages)
    private var selectedLanguages

    @Catalogue(\.selectedCategories)
    private var selectedCategories

    @Quotes(\.selectedSources)
    private var selectedSources

    @State private var searchText = ""
    @State private var selectedScope: SearchScope = .all

    public init() {}

    public var body: some View {
        NavigationStack {
            SearchContent(
                term: searchText.isEmpty ? nil : searchText,
                scope: selectedScope,
                selectedLanguages: selectedLanguages,
                selectedCategories: selectedCategories,
                selectedSources: selectedSources
            )
            .feed(.posts)
            .feed(.quotes)
            .feed(.catalogueSearch)
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
    }
}

// MARK: - Content (owns the feeds; SearchTab injects them above)

private struct SearchContent: View {

    @Feed(PostsQuery.self)
    private var posts

    @Feed(QuotesQuery.self)
    private var quotes

    @Feed(CatalogueSearchQuery.self)
    private var catalogueSearch

    @Environment(\.modelContext)
    private var modelContext

    @State private var catalogueEngine = CatalogueSearchEngine()

    let term: String?
    let scope: SearchScope
    let selectedLanguages: Set<Language>
    let selectedCategories: Set<CatalogueCategory>
    let selectedSources: Set<QuoteSourceFilter>

    /// The three feeds' typed inputs for the current term + filters — bundled so one value can
    /// key the `.task` below; `nil` when not searching. View-local, not a domain type.
    private struct SearchQueries: Hashable {
        let posts: PostsQuery
        let quotes: QuotesQuery
        let catalogue: CatalogueSearchQuery
    }

    private var queries: SearchQueries? {
        guard let term else { return nil }
        let languages = selectedLanguages.apiValues
        return SearchQueries(
            posts: PostsQuery(languages: selectedLanguages, term: term),
            quotes: QuotesQuery(languages: selectedLanguages, sources: selectedSources.apiValues, term: term),
            catalogue: CatalogueSearchQuery(term: term, types: selectedCategories.apiValues, languages: languages)
        )
    }

    var body: some View {
        Group {
            if let term {
                SearchResultsView(
                    term: term,
                    scope: scope,
                    catalogueEngine: catalogueEngine,
                    selectedLanguages: selectedLanguages,
                    selectedCategories: selectedCategories,
                    selectedSources: selectedSources
                )
            } else {
                ContentUnavailableView(
                    "Search",
                    systemImage: "magnifyingglass",
                    description: Text("Posts, songs, books, movies, and more.")
                )
            }
        }
        // Fire all network searches in parallel when the term or a filter changes — each
        // model supersedes its own in-flight request, so the last input wins per feed.
        .task(id: queries) {
            guard let queries else {
                catalogueEngine.clear()
                return
            }
            let term = queries.catalogue.term
            // Local catalogue search runs immediately.
            catalogueEngine.search(term: term, in: modelContext, categories: selectedCategories, languages: selectedLanguages)
            // All three network searches fire concurrently, each with its own typed input.
            await withTaskGroup(of: Void.self) { group in
                group.addTask { [posts] in await posts.fetch(queries.posts) }
                group.addTask { [catalogueSearch] in await catalogueSearch.fetch(queries.catalogue) }
                group.addTask { [quotes] in await quotes.fetch(queries.quotes) }
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
