import Vapor
import Fluent
import JWT

public struct APITokenAuthenticator: AsyncRequestAuthenticator {

    public init() {}

    public func authenticate(request: Request) async throws {
        guard let bearer = request.headers.bearerAuthorization else { return }
        let payload = try await request.jwt.verify(bearer.token, as: AppTokenPayload.self)
        guard let userID = Int(payload.sub.value),
              let user = try await User.find(userID, on: request.db)
        else { return }
        request.auth.login(user)
    }
}
