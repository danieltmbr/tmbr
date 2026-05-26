import SwiftUI
import ApiKit

@main
struct tmbr: App {
    private let config: APIConfig
    private let authState: AuthState

    init() {
        print("Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")
        config = .fromInfoPlist()
        if let saved = Keychain.loadToken() {
            Task { await config.auth.set(saved) }
        }
        authState = AuthState(config: config)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authState)
        }
    }
}
