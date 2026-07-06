import SwiftUI
import SwiftData
import AppApi
import AppCore
import AppPersistence
import TmbrCore

/// Reader — public, read-only. Plain on-disk SwiftData cache; no auth, no account.
/// Data enters lazily: the Blog tab's `refresh` fetches public posts + upserts (`ReaderPosts`).
/// The shared UI's seam stays at its defaults: `canAuthor = false`, `accountToolbar = .none`.
@main
struct ReaderApp: App {

    private let container: ModelContainer

    private let blog: BlogModel
    private let catalogue: CatalogueModel
    private let quotes: QuotesModel
    private let preferences = PreferencesModel()

    init() {
        do {
            container = try ModelContainer(for: AppSchema.schema)
        } catch {
            fatalError("Failed to create Reader ModelContainer: \(error)")
        }
        let postStore = PostStore(context: container.mainContext)
        let loader = PostsLoader.posts(baseURL: Self.apiBaseURL)
        let posts = ReaderPosts(loader: loader, store: postStore)
        let userDefaults = UserDefaults.standard
        let lastFetchedKey = "reader.blog.lastFetched"
        let postSearchLoader = PostSearchLoader.searchPosts(baseURL: Self.apiBaseURL)
        blog = BlogModel(
            refresh: {
                try await posts.refreshPosts()
                let now = Date.now
                userDefaults.set(now, forKey: lastFetchedKey)
                return now
            },
            loadMore: { try await posts.loadMore() },
            search: { term in
                let results = try await postSearchLoader.load(from: PostSearchQuery(term: term))
                try await postStore.upsert(results.items)
            },
            lastFetched: userDefaults.object(forKey: lastFetchedKey) as? Date
        )

        let catalogueStore = CatalogueStore(context: container.mainContext)
        let catalogueSync = SyncGroup.catalogue(baseURL: Self.apiBaseURL, store: catalogueStore)
        let catalogueSearchLoader = CatalogueSearchLoader.searchCatalogue(baseURL: Self.apiBaseURL)
        catalogue = CatalogueModel(
            refresh: { try await catalogueSync.run() },
            search: { term in
                let response = try await catalogueSearchLoader.load(from: CatalogueSearchQuery(term: term))
                try await catalogueStore.upsertSearch(response)
            }
        )

        let quoteSearchLoader = QuoteSearchLoader.searchQuotes(baseURL: Self.apiBaseURL)
        quotes = QuotesModel(search: { term in
            let results = try await quoteSearchLoader.load(from: QuoteSearchQuery(term: term))
            try await catalogueStore.upsert(results)
        })
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .blog(blog)
                .catalogue(catalogue)
                .quotes(quotes)
                .preferences(preferences)
                .environment(\.apiBaseURL, Self.apiBaseURL)
        }
        .modelContainer(container)

        #if os(macOS)
        Settings {
            PreferencesView()
                .preferences(preferences)
        }
        #endif
    }

    private static var apiBaseURL: URL {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              !raw.isEmpty, let url = URL(string: raw) else {
            fatalError("APIBaseURL missing or invalid in Info.plist")
        }
        return url
    }
}
