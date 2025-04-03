import Vapor
import Leaf
import Fluent
import JWT

public func configureAuth(_ app: Application) throws {
    
    app.middleware.use(SessionsMiddleware(session: app.sessions.driver))
    app.jwt.apple.applicationIdentifier = Environment.signIn.appID
    
    // Handle POST callback from Apple Sign In
    app.post("apple", "auth") { req async throws -> Response in
        let callbackData = try req.content.decode(AppleCallbackData.self)
        let appleIdentity = try await req.jwt.apple.verify(callbackData.id_token)

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
    
    let user: User?
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code)
        self.id_token = try container.decode(String.self, forKey: .id_token)
        self.state = try container.decodeIfPresent(String.self, forKey: .state)
        
        let userString = try container.decodeIfPresent(String.self, forKey: .user)
        if let userString = userString, let data = userString.data(using: .utf8) {
            self.user = try JSONDecoder().decode(User.self, from: data)
        } else {
            self.user = nil
        }
    }
}
