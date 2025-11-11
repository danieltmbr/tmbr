import Vapor
import AuthKit
import Crypto
import JWT
import Foundation
import Core

struct AuthAPIController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        // TODO: Implement oroper SignIn + SignOut
        routes.post("api", "apple", "auth") { req async throws -> Response in
            _ = try await authorizedUser(from: req)
            // TODO: Return token
            let response = Response(status: .ok)
            try response.content.encode(["redirect": "/"]) // or any post-auth URL
            return response
        }
    }
    
    private func authorizedUser(from request: Request) async throws -> User {
        let callbackData = try request.content.decode(AppleCallbackData.self)
        let appleIdentity = try await request.jwt.apple.verify(callbackData.id_token)
        
        // API flow: require nonce, no session/state
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
