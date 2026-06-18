import Vapor
import Fluent
import JWT

public struct AppleSignInAuthenticator: AsyncMiddleware {
    
    public init() {}
    
    public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
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
