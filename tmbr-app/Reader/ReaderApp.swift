import SwiftUI
import SwiftData
import CoreApp

/// Reader — public, read-only. Plain on-disk SwiftData cache; no auth, no account.
/// Data enters the DB lazily (per-screen fetch+upsert) — wired in a later workstream.
/// The shared UI's seam stays at its defaults: `canAuthor = false`, `accountToolbar = .none`.
@main
struct ReaderApp: App {
    let container: ModelContainer

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
        }
        .modelContainer(container)
    }
}
