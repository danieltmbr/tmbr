import SwiftUI

@main
struct tmbr: App {

    private let authState: AuthState

    init() {
        authState = AuthState(config: .fromInfoPlist(), keychain: Keychain())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authState)
        }
    }
}
