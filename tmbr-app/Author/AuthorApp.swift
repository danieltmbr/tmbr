import SwiftUI

@main
struct AuthorApp: App {

    private let account: AccountModel

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
        }
    }
}
