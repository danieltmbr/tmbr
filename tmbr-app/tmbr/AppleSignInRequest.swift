struct AppleSignInInput: Encodable, Sendable {
    let identityToken: String
    let authCode: String
    let nonce: String
    let userPayload: String?

    enum CodingKeys: String, CodingKey {
        case identityToken = "id_token"
        case authCode = "code"
        case nonce
        case userPayload = "user"
    }
}
