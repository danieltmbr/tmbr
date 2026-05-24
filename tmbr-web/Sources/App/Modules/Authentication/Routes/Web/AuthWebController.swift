import Vapor
import AuthKit
import Crypto
import JWT
import Foundation
import Core


struct AuthWebController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        routes.get("signin", page: .signIn)
        routes.post("apple", "auth", use: signIn)

        routes.get("signout", page: .signOut)
        routes.post("signout", use: signOut)
    }
    
    @Sendable
    private func signIn(_ req: Request) async throws -> Response {
        let callbackData = try req.content.decode(AppleCallbackData.self)
        let appleIdentity = try await req.jwt.apple.verify(callbackData.id_token)
        
        guard let returnedState = callbackData.state else {
            throw Abort(.unauthorized, reason: "Missing state")
        }
        // Verify the JWT state using the application's configured signers.
        let statePayload: StatePayload = try await req.jwt.verify(returnedState, as: StatePayload.self)
        
        // If Apple provided a nonce in the id_token, verify it matches the state payload's nonce.
        if let tokenNonce = appleIdentity.nonce {
            let provided = statePayload.n
            let hashedProvided = sha256Hex(provided)
            guard tokenNonce == hashedProvided || tokenNonce == provided else {
                throw Abort(.unauthorized, reason: "Invalid nonce")
            }
        }
        
        let user = try await User.findOrCreate(
            in: req.db,
            appleID: appleIdentity.subject.value,
            email: appleIdentity.email,
            firstName: callbackData.user?.name?.firstName,
            lastName: callbackData.user?.name?.lastName
        )
        
        req.auth.login(user)
        req.session.authenticate(user)
        
        defer { req.redirectReturnDestination = nil }
        return req.redirect(to: req.redirectReturnDestination ?? "/")
    }
    
    @Sendable
    private func signOut(_ req: Request) async throws -> Page.Redirect {
        let redirect = Page.Redirect(destination: "/")
        guard req.auth.has(User.self) else { return redirect }
        struct CSRFForm: Content { let _csrf: String }
        let submitted = try? req.content.decode(CSRFForm.self)
        let sessionToken = req.session.data["csrf.signout"]
        defer { req.session.data["csrf.signout"] = nil }
        guard let submittedToken = submitted?._csrf, let sessionToken, submittedToken == sessionToken else {
            throw Abort(.forbidden, reason: "Invalid CSRF token")
        }
        req.auth.logout(User.self)
        req.session.unauthenticate(User.self)
        return redirect
    }
    
    private func sha256Hex(_ string: String) -> String {
        let data = Data(string.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

