import Vapor
import WebAuth
import Leaf
import Fluent
import JWT
import Crypto
import WebCore

struct Authentication: Module {
    
    private let permissions: PermissionScopes.Auth
    
    // private let commands: Commands.Posts
    
    init(
        permissions: PermissionScopes.Auth
//        commands: Commands.Posts
    ) {
        self.permissions = permissions
        // self.commands = commands
    }
    
    func configure(_ app: Application) async throws {
        app.migrations.add(CreateAccess())
        
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
        
        app.middleware.use(app.sessions.middleware)
        app.middleware.use(User.sessionAuthenticator())
        app.middleware.use(UserIDLoggingMiddleware())
        app.middleware.use(LanguagePreferenceMiddleware())

        // Skip Apple Sign In JWT setup when env vars are absent (e.g. test environment).
        if let appID = Environment.get("SIWA_APP_ID"),
           let secret = Environment.get("SIWA_STATE_SECRET") {
            app.jwt.apple.applicationIdentifier = appID
            await app.jwt.keys.add(
                hmac: HMACKey(from: secret),
                digestAlgorithm: .sha256
            )
        }

        await app.storage.setWithAsyncShutdown(
            PermissionService.Key.self,
            to: PermissionService()
        )
        
        try await app.permissions.add(scope: permissions)
    }
    
    func boot(_ routes: RoutesBuilder) async throws {
        try routes.register(collection: AuthAPIController())
        try routes
            .grouped(RecoverMiddleware())
            .register(collection: AuthWebController())
    }
}

extension Module where Self == Authentication {
    static var authentication: Self {
        Authentication(
            permissions: PermissionScopes.Auth()
        )
    }
}

