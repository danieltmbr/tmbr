import Foundation
import AuthenticationServices
import CoreApi
import CoreTmbr

/// The shared account model for the Author app — manages sign-in state, token storage,
/// and vends authenticated request loaders for other features.
@MainActor
@Observable
public final class AccountModel {

    private(set) var isSignedIn: Bool

    private let session: URLSession

    private let keychain: Keychain

    private let auth: AuthProvider

    private let signInLoader: RequestLoader<AppleSignInRequest>

    init(
        session: URLSession,
        keychain: Keychain,
        signInLoader: RequestLoader<AppleSignInRequest>
    ) {
        let savedToken = keychain.loadToken()
        self.session = session
        self.keychain = keychain
        self.auth = AuthProvider(token: savedToken)
        self.isSignedIn = savedToken != nil
        self.signInLoader = signInLoader
    }

    func loader<R: Request>(for request: R) -> RequestLoader<R> {
        RequestLoader(request: request, session: session, auth: auth)
    }

    func signIn(authorization: ASAuthorization, nonce: String) async throws {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8),
              let codeData = credential.authorizationCode,
              let authCode = String(data: codeData, encoding: .utf8)
        else {
            throw AccountError.invalidCredential
        }

        let response = try await signInLoader.load(from: AppleSignInData(
            code: authCode,
            idToken: identityToken,
            nonce: nonce,
            user: appleUser(from: credential)
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

    // Apple only sends name/email on first sign-in
    private func appleUser(from credential: ASAuthorizationAppleIDCredential) -> AppleSignInData.User? {
        let components = credential.fullName
        let hasName = components?.givenName != nil || components?.familyName != nil
        guard credential.email != nil || hasName else { return nil }
        let name: AppleSignInData.User.Name? = hasName
            ? .init(firstName: components?.givenName ?? "", lastName: components?.familyName ?? "")
            : nil
        return .init(email: credential.email, name: name)
    }

    enum AccountError: LocalizedError {
        case invalidCredential
        var errorDescription: String? { "Could not read Apple Sign In credential." }
    }
}
