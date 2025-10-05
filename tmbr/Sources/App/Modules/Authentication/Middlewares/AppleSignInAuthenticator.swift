import Vapor
import Fluent
import JWTKit

final class AppleSignInAuthenticator: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        do {
            let appleIdentity = try await request.jwt.apple.verify()
            let user = try await User.find(
                appleID: appleIdentity.subject.value,
                in: request.db
            )
            
            if let user {
                request.auth.login(user)
            } else {
                throw Abort(.unauthorized, reason: "User not found")
            }
            
            return try await next.respond(to: request)
        } catch {
            request.logger.error("User authentication failed. \(error)")
            throw Abort(.unauthorized, reason: "Authentication failed")
        }
    }
}
