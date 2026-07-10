import SwiftUI
import SwiftData
import AppCore
import AppPersistence

/// Reader — public, read-only. Plain on-disk SwiftData cache; no auth, no account.
/// Data enters lazily: feeds (`@Feed`) fetch public posts/quotes/catalogue and upsert; they
/// compose themselves from `\.apiBaseURL` + the feed descriptors' default pipelines.
/// The shared UI's seam stays at its defaults: `canAuthor = false`, `accountToolbar = .none`.
@main
struct ReaderApp: App {

    private let container: ModelContainer

    private let catalogue = CatalogueModel()

    private let quotes = QuotesModel()

    private let preferences = PreferencesModel()

    init() {
        do {
            container = try ModelContainer(for: AppSchema.schema)
        } catch {
            fatalError("Failed to create Reader ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .catalogue(catalogue)
                .quotes(quotes)
                .preferences(preferences)
                .environment(\.apiBaseURL, Self.baseURL)
        }
        .modelContainer(container)

        #if os(macOS)
        Settings {
            PreferencesView()
                .preferences(preferences)
        }
        #endif
    }

    private static var baseURL: URL {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              !raw.isEmpty, let url = URL(string: raw) else {
            fatalError("APIBaseURL missing or invalid in Info.plist")
        }
        return url
    }
}
