import SwiftUI
import SwiftData
import BackgroundTasks

private let backgroundSyncID = "me.tmbr.sync"

@main
struct tmbr: App {

    @Environment(\.scenePhase) private var scenePhase

    private let authState: AuthState
    private let container: ModelContainer
    private let syncEngine: SyncEngine
    private let blogModel: BlogModel
    private let catalogueModel: CatalogueModel
    private let networkMonitor: NetworkMonitor

    init() {
        let config = APIConfig.fromInfoPlist()
        let authState = AuthState(
            session: config.session,
            keychain: Keychain(),
            signInLoader: config.loader(for: .signIn(baseURL: config.baseURL))
        )

        // CatalogueItemRecord must be registered before its subclasses.
        let schema = Schema([
            NoteRecord.self,
            PostRecord.self,
            QuoteRecord.self,
            CatalogueItemRecord.self,
            SongRecord.self,
            AlbumRecord.self,
            BookRecord.self,
            MovieRecord.self,
            PodcastRecord.self,
            PlaylistRecord.self,
            OrphanRecord.self,
            UserRecord.self,
        ])
        let container = try! ModelContainer(for: schema)
        let syncEngine = SyncEngine(
            authState: authState,
            modelContext: container.mainContext,
            baseURL: config.baseURL
        )

        self.authState = authState
        self.container = container
        self.syncEngine = syncEngine
        self.blogModel = BlogModel(syncEngine: syncEngine)
        self.catalogueModel = CatalogueModel(syncEngine: syncEngine)
        self.networkMonitor = NetworkMonitor()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authState)
                .modelContainer(container)
                .blog(blogModel)
                .catalogue(catalogueModel)
                .environment(networkMonitor)
                .onReceive(NotificationCenter.default.publisher(for: .connectivityRestored)) { _ in
                    guard authState.isSignedIn else { return }
                    Task { try? await syncEngine.runSync() }
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                guard authState.isSignedIn else { return }
                Task { try? await syncEngine.runSync() }
            case .background:
                scheduleBackgroundSync()
            default:
                break
            }
        }
        .backgroundTask(.appRefresh(backgroundSyncID)) {
            guard authState.isSignedIn else { return }
            try? await syncEngine.runSync()
            scheduleBackgroundSync()
        }
    }

    private func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundSyncID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 min minimum
        try? BGTaskScheduler.shared.submit(request)
    }
}
