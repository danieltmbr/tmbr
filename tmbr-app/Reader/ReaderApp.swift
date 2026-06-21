import SwiftUI
import SwiftData
import CoreApp

/// Reader — public, read-only. Plain on-disk SwiftData cache; no auth, no account.
/// Data enters lazily: the Blog tab's `refresh` fetches public posts + upserts (`ReaderPosts`).
/// The shared UI's seam stays at its defaults: `canAuthor = false`, `accountToolbar = .none`.
@main
struct ReaderApp: App {
    
    let container: ModelContainer
    
    let blog: BlogModel

    init() {
        do {
            container = try ModelContainer(for: AppSchema.schema)
        } catch {
            fatalError("Failed to create Reader ModelContainer: \(error)")
        }
        let posts = ReaderPosts(
            baseURL: Self.apiBaseURL,
            context: container.mainContext
        )
        blog = BlogModel(
            refresh: { try await posts.refreshPosts() },
            loadMore: { try await posts.loadMore() }
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .blog(blog)
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
