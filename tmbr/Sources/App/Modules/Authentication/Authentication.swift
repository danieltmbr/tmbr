import Vapor
import Leaf
import Fluent
import JWT
import Crypto
import Core

struct Authentication: Module {
    func configure(_ app: Application) async throws {
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
        await app.jwt.keys.add(
            hmac: HMACKey(from: Environment.signIn.secret),
            digestAlgorithm: .sha256
        )
        app.middleware.use(User.sessionAuthenticator())
        
        app.migrations.add(CreateUser())
    }
    
    func boot(_ routes: RoutesBuilder) async throws {
        try routes.register(collection: AuthenticationAPIController())
        routes.get("signin", page: .signIn)
        let protected = routes.grouped(
            User.redirectMiddleware(path: "/signin")
        )
        protected.get("signout", page: .signOut)
    }
}

extension Module where Self == Authentication {
    static var authentication: Self {
        Authentication()
    }
}

