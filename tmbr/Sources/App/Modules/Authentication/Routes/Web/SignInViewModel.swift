import Foundation
import Vapor
import JWT

struct SignInViewModel: Encodable {
    
    private let clientId: String
    
    private let scope: String = "name email"
    
    private let redirectUrl: String
    
    private let state: String?
    
    private let nonce: String?
    
    private let popup: Bool = false
    
    init(
        clientId: String,
        redirectUrl: String,
        state: String? = nil,
        nonce: String? = nil
    ) {
        self.clientId = clientId
        self.redirectUrl = redirectUrl
        self.state = state
        self.nonce = nonce
    }
    
    static func withNonce(
        date: Date = .now,
        signedBy sign: @escaping (StatePayload) async throws -> String
    ) async rethrows -> SignInViewModel {
        let nonce = [UInt8].random(count: 16).base64
        let payload = StatePayload(
            n: nonce,
            iat: .init(value: date),
            exp: .init(value: date.addingTimeInterval(5 * 60))
        )
        let state = try await sign(payload)
        return SignInViewModel(
            clientId: Environment.signIn.appID,
            redirectUrl: Environment.signIn.redirectUrl,
            state: state,
            nonce: nonce
        )
    }
}
