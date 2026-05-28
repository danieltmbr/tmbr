#if DEBUG || VAPOR_TESTING
import Vapor
import AuthKit
import Fluent

// MARK: - Test-only routes

/// Registers routes available only in the .testing environment, so the live server can issue
/// sessions without Apple Sign In. Compiled out of release builds entirely.
func registerTestOnlyRoutes(_ app: Application) {
    guard app.environment == .testing else { return }
    // POST /__test/login
    // Body: { "userID": Int } — logs in an existing user
    // Body: {} or absent userID — creates a fresh test user and logs them in
    app.post("__test", "login") { req async throws -> Response in
        struct LoginPayload: Content { let userID: Int? }
        let payload = try req.content.decode(LoginPayload.self)
        let user: User
        if let userID = payload.userID,
           let found = try await User.find(userID, on: req.db) {
            user = found
        } else {
            let newUser = User(
                appleID: "ci-\(UUID().uuidString)",
                email: "ci@test.example",
                firstName: "CI",
                lastName: "Test",
                role: .standard
            )
            try await newUser.save(on: req.db)
            user = newUser
        }
        req.auth.login(user)
        req.session.authenticate(user)
        return Response(status: .ok)
    }
}
#endif
