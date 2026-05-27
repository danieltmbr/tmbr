import ApiKit
import TmbrCore

typealias AppleSignInRequest = BasicRequest<AppleSignInInput, AuthResponse>

extension Request where Self == AppleSignInRequest {
    static func signIn(baseURL: URL) -> Self {
        .post(baseURL: baseURL, path: "/api/apple/auth")
    }
}

struct AppleSignInInput: Encodable, Sendable {
    let identityToken: String
    let authCode: String
    let nonce: String
    let userPayload: String?

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identityToken, forKey: .identityToken)
        try container.encode(authCode, forKey: .authCode)
        try container.encode(nonce, forKey: .nonce)
        try container.encodeIfPresent(userPayload, forKey: .userPayload)
    }

    private enum CodingKeys: String, CodingKey {
        case identityToken = "id_token"
        case authCode = "code"
        case nonce
        case userPayload = "user"
    }
}
