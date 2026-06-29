import JWT
import Foundation

public struct AppTokenPayload: JWTPayload {
    public var sub: SubjectClaim
    public var exp: ExpirationClaim
    public var iat: IssuedAtClaim

    public static let expiry: TimeInterval = 60 * 60 * 24 * 30 // 30 days

    public init(userID: Int) {
        let now = Date()
        self.sub = .init(value: String(userID))
        self.exp = .init(value: now.addingTimeInterval(Self.expiry))
        self.iat = .init(value: now)
    }

    public func verify(using algorithm: some JWTAlgorithm) async throws {
        try exp.verifyNotExpired()
    }
}
