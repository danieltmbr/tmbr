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
        blog = BlogModel(
            refresh: {
                try await posts.refreshPosts()
                let now = Date.now
                userDefaults.set(now, forKey: lastFetchedKey)
                return now
            },
            loadMore: { try await posts.loadMore() },
            search: { term in try await posts.search(term: term) },
            lastFetched: userDefaults.object(forKey: lastFetchedKey) as? Date
        )

        let catalogueStore = CatalogueStore(context: container.mainContext)
        let catalogueSync = SyncGroup.catalogue(baseURL: Self.apiBaseURL, store: catalogueStore)
        let catalogueSearchLoader = CatalogueSearchLoader.searchCatalogue(baseURL: Self.apiBaseURL)
        let readerCatalogue = ReaderCatalogue(loader: catalogueSearchLoader, store: catalogueStore)
        catalogue = CatalogueModel(
            refresh: { try await catalogueSync.run() },
            search: { term in try await readerCatalogue.search(term: term) },
            loadMore: { try await readerCatalogue.loadMore() }
        )

        let quoteSearchLoader = QuoteSearchLoader.searchQuotes(baseURL: Self.apiBaseURL)
        let readerQuotes = ReaderQuotes(loader: quoteSearchLoader, store: catalogueStore)
        quotes = QuotesModel(
            search: { term in try await readerQuotes.search(term: term) },
            loadMore: { try await readerQuotes.loadMore() }
        )
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
