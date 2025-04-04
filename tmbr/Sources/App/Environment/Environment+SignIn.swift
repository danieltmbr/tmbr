import Vapor

extension Environment {
    struct SignIn: Sendable {
        /// Service bundle identifier
        let appID = Environment.get("SIWA_APP_ID")!
        
        /// Registered redirect url
        let redirectUrl = Environment.get("SIWA_REDIRECT_URL")!
        
        /// Team identifier
        let teamID = Environment.get("SIWA_TEAM_ID")!
        
        /// Key identifier
        let keyID = Environment.get("SIWA_KEY_ID")!
        
        /// Contents of the downloaded key file
        let key = Environment.get("SIWA_KEY")!
    }

    /// Evironment values for Apple Sign In
    static let signIn = SignIn()
}
