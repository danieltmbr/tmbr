import Vapor
import WebAuth

struct UserIDLoggingMiddleware: AsyncMiddleware {

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        if let userID = request.auth.get(User.self)?.id {
            request.logger[metadataKey: "userID"] = .string(String(userID))
        }
        return try await next.respond(to: request)
    }
}
