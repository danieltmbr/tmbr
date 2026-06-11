import Vapor
import Fluent
import JWT

public struct AppleSignInTokenParser: AsyncMiddleware {

    public init() {}

    public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        if let identity = try? await request.jwt.apple.verify(),
           let user = try? await User.find(appleID: identity.subject.value, in: request.db) {
            request.auth.login(user)
        }
        return try await next.respond(to: request)
    }
}
