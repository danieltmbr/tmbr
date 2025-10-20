import Vapor
import Crypto
import JWT
import Foundation

struct AuthenticationAPIController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        routes.post("apple", "auth") { req async throws -> Response in
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
            return req.redirect(to: "/")
        }
        
        routes.post("api", "apple", "auth") { req async throws -> Response in
            _ = try await authorizedUser(from: req)
            // TODO: Return token
            let response = Response(status: .ok)
            try response.content.encode(["redirect": "/"]) // or any post-auth URL
            return response
        }
        
        routes.post("signout") { req async throws -> Response in
            struct CSRFForm: Content { let _csrf: String }
            let submitted = try? req.content.decode(CSRFForm.self)
            let sessionToken = req.session.data["csrf.signout"]
            defer { req.session.data["csrf.signout"] = nil }
            guard let submittedToken = submitted?._csrf, let sessionToken, submittedToken == sessionToken else {
                throw Abort(.forbidden, reason: "Invalid CSRF token")
            }
            req.auth.logout(User.self)
            req.session.unauthenticate(User.self)
            return req.redirect(to: "/signin")
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

private struct AppleCallbackData: Content {
    struct User: Content {
        
        struct Name: Content {
            
            let firstName: String
            
            let lastName: String
        }
        
        let email: String?
        
        let name: Name?
    }
    
    let code: String
    
    let id_token: String
    
    let state: String?
    
    let nonce: String?
    
    let user: User?
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code)
        self.id_token = try container.decode(String.self, forKey: .id_token)
        self.state = try container.decodeIfPresent(String.self, forKey: .state)
        self.nonce = try container.decodeIfPresent(String.self, forKey: .nonce)
        
        let userString = try container.decodeIfPresent(String.self, forKey: .user)
        if let userString = userString, let data = userString.data(using: .utf8) {
            self.user = try JSONDecoder().decode(User.self, from: data)
        } else {
            self.user = nil
        }
    }
}
