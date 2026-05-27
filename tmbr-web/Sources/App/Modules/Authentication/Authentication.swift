import Vapor
import AuthKit
import Leaf
import Fluent
import JWT
import Crypto
import Core

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

        app.jwt.apple.applicationIdentifier = Environment.signIn.appID
        await app.jwt.keys.add(
            hmac: HMACKey(from: Environment.signIn.secret),
            digestAlgorithm: .sha256
        )

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

