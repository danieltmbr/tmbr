import SwiftUI
import SwiftData

@main
struct tmbr: App {

    @Environment(\.scenePhase) private var scenePhase

    private let authState: AuthState
    private let container: ModelContainer
    private let syncEngine: SyncEngine
    private let blogModel: BlogModel
    private let catalogueModel: CatalogueModel

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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authState)
                .modelContainer(container)
                .blog(blogModel)
                .catalogue(catalogueModel)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active, authState.isSignedIn else { return }
            Task { try? await syncEngine.runSync() }
        }
    }
}
