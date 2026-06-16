@testable import Backend
import VaporTesting
import Testing
import Fluent
import Vapor
import CoreAuth

// MARK: - App lifecycle

/// Boots the app in .testing mode, runs auto-migrate before and auto-revert after each test.
///
/// Requires SIWA_* and DATABASE_* environment variables to be set in the Xcode scheme.
func withApp(_ test: (Application) async throws -> ()) async throws {
    let app = try await Application.make(.testing)
    do {
        try await configure(app)
        registerTestOnlyRoutes(app)
        try await app.autoMigrate()
        try await test(app)
        try await app.autoRevert()
    } catch {
        try? await app.autoRevert()
        try await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}

/// Boots the app, creates an authenticated user, and passes a ready-to-use Cookie header.
func withAuthenticatedApp(
    role: User.Role = .standard,
    _ test: (Application, HTTPHeaders) async throws -> ()
) async throws {
    try await withApp { app in
        let (_, headers) = try await makeTestUser(role: role, on: app)
        try await test(app, headers)
    }
}

// MARK: - Test user helpers

@discardableResult
func makeTestUser(
    role: User.Role = .standard,
    on app: Application
) async throws -> (User, HTTPHeaders) {
    let user = User(
        appleID: "test-apple-\(UUID().uuidString)",
        email: "test@example.com",
        firstName: "Test",
        lastName: "User",
        role: role
    )
    try await user.save(on: app.db)

    var cookieHeader = ""
    try await app.testing().test(
        .POST, "/__test/login",
        beforeRequest: { req in
            struct LoginPayload: Content { let userID: Int }
            guard let id = user.id else { throw Abort(.internalServerError) }
            try req.content.encode(LoginPayload(userID: id))
        },
        afterResponse: { res async in
            // Extract just "vapor_session=<value>" from the full Set-Cookie header
            if let setCookie = res.headers.first(name: "Set-Cookie"),
               let cookiePart = setCookie.components(separatedBy: ";").first {
                cookieHeader = cookiePart
            }
        }
    )

    var headers = HTTPHeaders()
    if !cookieHeader.isEmpty {
        headers.add(name: "Cookie", value: cookieHeader)
    }
    return (user, headers)
}

// MARK: - Test-only routes

/// Registers a `POST /__test/login` endpoint that is only available in the `.testing` environment.
/// This bypasses Apple Sign In so tests can create authenticated sessions directly.
private func registerTestOnlyRoutes(_ app: Application) {
    guard app.environment == .testing else { return }
    app.post("__test", "login") { req async throws -> Response in
        struct LoginPayload: Content { let userID: Int }
        let payload = try req.content.decode(LoginPayload.self)
        guard let user = try await User.find(payload.userID, on: req.db) else {
            throw Abort(.notFound)
        }
        req.auth.login(user)
        req.session.authenticate(user)
        return Response(status: .ok)
    }
}
