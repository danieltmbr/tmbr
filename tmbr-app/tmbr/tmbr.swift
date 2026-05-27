import SwiftUI

@main
struct tmbr: App {

    private let authState: AuthState

    init() {
        let config = APIConfig.fromInfoPlist()
        authState = AuthState(
            session: config.session,
            keychain: Keychain(),
            signInLoader: config.loader(for: .signIn(baseURL: config.baseURL))
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authState)
        }
    }
}
