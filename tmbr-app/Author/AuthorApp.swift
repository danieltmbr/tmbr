import SwiftUI
import AppCore

@main
struct AuthorApp: App {

    private let account: AccountModel
    
    let preferences = PreferencesModel()

    init() {
        let config = APIConfig.fromInfoPlist()
        account = AccountModel(
            session: config.session,
            keychain: Keychain(),
            signInLoader: config.loader(for: .signIn(baseURL: config.baseURL))
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .account(account)
                .preferences(preferences)
        }

        #if os(macOS)
        Settings {
            PreferencesView()
                .preferences(preferences)
        }
        #endif
    }
}
