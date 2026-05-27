import SwiftUI
import AuthenticationServices
import CryptoKit

struct SignInView: View {
    @Environment(AuthState.self) private var authState
    @State private var currentNonce: String = ""
    @State private var error: Error?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("tmbr")
                .font(.largeTitle.bold())
            Spacer()
            SignInWithAppleButton(.signIn, onRequest: configure, onCompletion: handle)
                .frame(height: 50)
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
        }
        .alert("Sign In Failed", isPresented: .constant(error != nil), presenting: error) { _ in
            Button("OK") { error = nil }
        } message: { err in
            Text(err.localizedDescription)
        }
    }

    private func configure(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonce()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    private func handle(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            let nonce = currentNonce
            Task {
                do {
                    try await authState.signIn(authorization: authorization, nonce: nonce)
                } catch {
                    self.error = error
                }
            }
        case .failure(let err):
            let asErr = err as? ASAuthorizationError
            if asErr?.code == .canceled { return }
            error = err
        }
    }

    private func randomNonce(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return bytes.map { String(format: "%02x", $0) }.joined()
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
