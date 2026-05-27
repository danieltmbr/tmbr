import SwiftUI
import ApiKit

@main
struct tmbr: App {
    private let config: APIConfig
    private let authState: AuthState

    init() {
        print("Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")
        let token = Keychain.loadToken()
        config = .fromInfoPlist(token: token)
        authState = AuthState(config: config, isSignedIn: token != nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authState)
        }
    }
}
