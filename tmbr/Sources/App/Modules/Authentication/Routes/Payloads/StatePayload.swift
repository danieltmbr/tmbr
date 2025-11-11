import JWT

struct StatePayload: JWTPayload {
    let n: String
    let iat: IssuedAtClaim
    let exp: ExpirationClaim

    func verify(using algorithm: some JWTAlgorithm) async throws {
        try exp.verifyNotExpired()
    }
}
