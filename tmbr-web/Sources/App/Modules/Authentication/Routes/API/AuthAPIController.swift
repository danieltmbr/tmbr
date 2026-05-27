import Vapor
import AuthKit
import Crypto
import JWT
import Foundation
import Core
import TmbrCore

struct AuthAPIController: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        routes.post("api", "apple", "auth", use: signIn)
    }

    @Sendable
    private func signIn(_ req: Request) async throws -> AuthResponse {
        let user = try await authorizedUser(from: req)
        guard let userID = user.id else {
            throw Abort(.internalServerError, reason: "User has no ID")
        }
        let payload = AppTokenPayload(userID: userID)
        let token = try await req.jwt.sign(payload)
        return AuthResponse(token: token)
    }

    private func authorizedUser(from request: Request) async throws -> User {
        let callbackData = try request.content.decode(AppleCallbackData.self)
        let appleIdentity = try await request.jwt.apple.verify(callbackData.idToken, applicationIdentifier: Environment.signIn.nativeAppID)

        guard let tokenNonce = appleIdentity.nonce else {
            throw Abort(.unauthorized, reason: "Token missing nonce")
        }
        guard let providedNonce = callbackData.nonce else {
            throw Abort(.unauthorized, reason: "Missing nonce")
        }
        let hashedProvided = sha256Hex(providedNonce)
        guard tokenNonce == hashedProvided || tokenNonce == providedNonce else {
            throw Abort(.unauthorized, reason: "Invalid nonce")
        }

        let appleID = appleIdentity.subject.value
        let email = appleIdentity.email
        let name = callbackData.user?.name

        return try await User.findOrCreate(
            in: request.db,
            appleID: appleID,
            email: email,
            firstName: name?.firstName,
            lastName: name?.lastName
        )
    }

    private func sha256Hex(_ string: String) -> String {
        let data = Data(string.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
