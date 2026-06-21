import SwiftUI
import SwiftData
import CoreApp

/// Personal — private, single-user. CloudKit mirrors writes across the user's devices, no backend.
/// `canAuthor` stays `false` until the offline write path lands; no account UI (iCloud is implicit).
///
/// NOTE: ships with a plain on-disk container for now. The `.private` CloudKit container + entitlement
/// (`ModelConfiguration(cloudKitDatabase: .private("iCloud.me.tmbr.personal"))`) land with the Personal
/// stage, once the container is provisioned — see native-apps-architecture.md.
@main
struct PersonalApp: App {
    let container: ModelContainer

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
        }
        .modelContainer(container)
    }
}
