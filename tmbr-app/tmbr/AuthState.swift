import Foundation
import AuthenticationServices
import ApiKit
import TmbrCore

@Observable
final class AuthState {

    private(set) var isSignedIn: Bool

    private let config: APIConfig

    private let keychain: Keychain

    private let auth: AuthProvider

    private let signInLoader: RequestLoader<BasicRequest<AppleSignInInput, AuthResponse>>

    init(config: APIConfig, keychain: Keychain) {
        let savedToken = keychain.loadToken()
        self.config = config
        self.keychain = keychain
        self.auth = AuthProvider(token: savedToken)
        self.isSignedIn = savedToken != nil
        self.signInLoader = config.loader(for: .signIn(baseURL: config.baseURL))
    }

    func loader<R: Request>(for request: R) -> RequestLoader<R> {
        RequestLoader(request: request, session: config.session, auth: auth)
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

        keychain.saveToken(response.token)
        await auth.set(response.token)
        isSignedIn = true
    }

    func signOut() async {
        await auth.set(nil)
        keychain.deleteToken()
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
