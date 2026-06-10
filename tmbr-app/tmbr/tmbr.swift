import SwiftUI
import SwiftData

@main
struct tmbr: App {

    private let authState: AuthState
    private let container: ModelContainer

    init() {
        let config = APIConfig.fromInfoPlist()
        authState = AuthState(
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
        container = try! ModelContainer(for: schema)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authState)
                .modelContainer(container)
        }
    }
}
