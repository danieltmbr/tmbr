import SwiftUI
import SwiftData
import CoreApi
import CoreApp

/// Reader — public, read-only. Plain on-disk SwiftData cache; no auth, no account.
/// Data enters lazily: the Blog tab's `refresh` fetches public posts + upserts (`ReaderPosts`).
/// The shared UI's seam stays at its defaults: `canAuthor = false`, `accountToolbar = .none`.
@main
struct ReaderApp: App {

    let container: ModelContainer

    let blog: BlogModel
    let catalogue: CatalogueModel

    init() {
        do {
            container = try ModelContainer(for: AppSchema.schema)
        } catch {
            fatalError("Failed to create Reader ModelContainer: \(error)")
        }
        let loader = PostsLoader.posts(baseURL: Self.apiBaseURL)
        let store = PostStore(context: container.mainContext)
        let posts = ReaderPosts(loader: loader, store: store)
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
            lastFetched: userDefaults.object(forKey: lastFetchedKey) as? Date
        )

        let catalogueStore = CatalogueStore(context: container.mainContext)
        let catalogueSync = SyncGroup.catalogue(baseURL: Self.apiBaseURL, store: catalogueStore)
        catalogue = CatalogueModel(refresh: { try await catalogueSync.run() })
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .blog(blog)
                .catalogue(catalogue)
                .environment(\.apiBaseURL, Self.apiBaseURL)
        }
        .modelContainer(container)
    }

    private static var apiBaseURL: URL {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              !raw.isEmpty, let url = URL(string: raw) else {
            fatalError("APIBaseURL missing or invalid in Info.plist")
        }
        return url
    }
}
