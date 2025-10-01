import Vapor
import Leaf
import Fluent
import JWT
import CryptoKit

public func configureAuth(_ app: Application) throws {
    app.sessions.use(.memory)
    app.sessions.configuration.cookieFactory = { sessionID in
        .init(
            string: sessionID.string,
            expires: nil,
            maxAge: nil,
            domain: nil,
            path: "/",
            isSecure: true,
            isHTTPOnly: true,
            sameSite: HTTPCookies.SameSitePolicy.none
        )
    }
    app.middleware.use(SessionsMiddleware(session: app.sessions.driver))
    app.jwt.apple.applicationIdentifier = Environment.signIn.appID
    app.middleware.use(User.sessionAuthenticator())
    
    app.post("apple", "auth") { req async throws -> Response in
        let callbackData = try req.content.decode(AppleCallbackData.self)
        let appleIdentity = try await req.jwt.apple.verify(callbackData.id_token)
        
        if let storedState = req.session.data["state"] {
            guard let returnedState = callbackData.state, storedState == returnedState else {
                throw Abort(.unauthorized, reason: "Invalid state")
            }
            req.session.data["state"] = nil
        } else {
            guard let tokenNonce = appleIdentity.nonce else {
                throw Abort(.unauthorized, reason: "Token missing nonce")
            }
            guard let providedNonce = callbackData.nonce else {
                throw Abort(.unauthorized, reason: "Missing nonce")
            }
            // Compare against SHA-256 of the raw nonce (most iOS clients send SHA-256 in the request),
            // and also allow direct equality in case the client already provided a hashed nonce.
            let hashedProvided = sha256Hex(providedNonce)
            guard tokenNonce == hashedProvided || tokenNonce == providedNonce else {
                throw Abort(.unauthorized, reason: "Invalid nonce")
            }
        }

        let appleID = appleIdentity.subject.value
        let email = appleIdentity.email
        let name = callbackData.user?.name
        
        let user = try await User.findOrCreate(
            in: req.db,
            appleID: appleID,
            email: email,
            firstName: name?.firstName,
            lastName: name?.lastName
        )
        req.auth.login(user)
        req.session.authenticate(user)
        
        return req.redirect(to: "/")
    }
    
    app.post("signout") { req async throws -> Response in
        req.auth.logout(User.self)
        req.session.unauthenticate(User.self)
        return req.redirect(to: "/")
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

private func sha256Hex(_ string: String) -> String {
    let data = Data(string.utf8)
    let digest = SHA256.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
}
