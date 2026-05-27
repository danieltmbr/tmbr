import Foundation
import AuthenticationServices
import ApiKit
import TmbrCore

@Observable
final class AuthState {
    private(set) var isSignedIn: Bool
    private let config: APIConfig
    private let signInLoader: RequestLoader<AppleSignInRequest>

    init(config: APIConfig, isSignedIn: Bool = false) {
        self.config = config
        self.signInLoader = RequestLoader(
            request: AppleSignInRequest(baseURL: config.baseURL),
            session: config.session
        )
        self.isSignedIn = isSignedIn
    }

    func signIn(authorization: ASAuthorization, nonce: String) async throws {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8),
              let codeData = credential.authorizationCode,
              let authCode = String(data: codeData, encoding: .utf8)
        else {
            throw AuthError.invalidCredential
        }

        let response = try await signInLoader.load(from: .init(
            identityToken: identityToken,
            authCode: authCode,
            nonce: nonce,
            userPayload: encodeUserPayload(credential: credential)
        ))

        Keychain.saveToken(response.token)
        await config.auth.set(response.token)
        isSignedIn = true
    }

    func signOut() async {
        await config.auth.set(nil)
        Keychain.deleteToken()
        isSignedIn = false
    }

    // Apple only sends name/email on first sign-in; encode as JSON string to match backend's AppleCallbackData
    private func encodeUserPayload(credential: ASAuthorizationAppleIDCredential) -> String? {
        struct Name: Encodable { let firstName: String; let lastName: String }
        struct UserInfo: Encodable { let email: String?; let name: Name? }

        let components = credential.fullName
        let name: Name? = (components?.givenName != nil || components?.familyName != nil)
            ? Name(firstName: components?.givenName ?? "", lastName: components?.familyName ?? "")
            : nil

        guard credential.email != nil || name != nil else { return nil }
        let info = UserInfo(email: credential.email, name: name)
        return try? String(data: JSONEncoder().encode(info), encoding: .utf8)
    }

    enum AuthError: LocalizedError {
        case invalidCredential
        var errorDescription: String? { "Could not read Apple Sign In credential." }
    }
}
