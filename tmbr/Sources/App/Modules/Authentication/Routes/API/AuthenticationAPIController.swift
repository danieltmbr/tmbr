import Vapor
import CryptoKit

struct AuthenticationAPIController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        routes.post("apple", "auth") { req async throws -> Response in
            let user = try await authorizedUser(from: req)
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

