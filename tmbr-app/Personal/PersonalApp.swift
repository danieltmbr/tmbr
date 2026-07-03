import SwiftUI
import SwiftData
import AppCore
import AppPersistence

/// Personal — private, single-user. CloudKit mirrors writes across the user's devices, no backend.
/// `canAuthor` stays `false` until the offline write path lands; no account UI (iCloud is implicit).
///
/// NOTE: ships with a plain on-disk container for now. The `.private` CloudKit container + entitlement
/// (`ModelConfiguration(cloudKitDatabase: .private("iCloud.me.tmbr.personal"))`) land with the Personal
/// stage, once the container is provisioned — see native-apps-architecture.md.
@main
struct PersonalApp: App {
    let container: ModelContainer
    // No-op refresh — Personal's data is CloudKit-mirrored (no fetch). Empty until the write path lands.
    let blog = BlogModel()
    let catalogue = CatalogueModel()
    let preferences = PreferencesModel()

    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            container = try ModelContainer(for: AppSchema.schema)
        } catch {
            fatalError("Failed to create Personal ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .blog(blog)
                .catalogue(catalogue)
                .preferences(preferences)
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        preferences.refreshFromDefaults()
                    }
                }
        }
        .modelContainer(container)

        #if os(macOS)
        Settings {
            PreferencesView()
                .preferences(preferences)
        }
        #endif
    }
}
