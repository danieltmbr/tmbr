import Vapor

extension Environment {
    struct SignIn: Sendable {
        /// Services ID used by the web sign-in flow
        let appID = Environment.get("SIWA_APP_ID")!

        /// Bundle ID used by the native app sign-in flow
        let nativeAppID = Environment.get("SIWA_NATIVE_APP_ID") ?? { fatalError("SIWA_NATIVE_APP_ID missing — set the bundle ID of the native app in your environment") }()
        
        /// Registered redirect url
        let redirectUrl = Environment.get("SIWA_REDIRECT_URL")!
        
        /// Team identifier
        let teamID = Environment.get("SIWA_TEAM_ID")!
        
        /// Key identifier
        let keyID = Environment.get("SIWA_KEY_ID")!
        
        /// Contents of the downloaded key file
        let key = Environment.get("SIWA_KEY")!
        
        /// Contents of the downloaded key file
        let secret = Environment.get("SIWA_STATE_SECRET")!
    }

    /// Evironment values for Apple Sign In
    static let signIn = SignIn()
}
