import WebAuth
import Fluent
import Vapor
import WebCore
import TmbrCore

struct Posts: Module {
    
    private let permissions: PermissionScopes.Posts
    
    private let commands: Commands.Posts
    
    init(
        permissions: PermissionScopes.Posts,
        commands: Commands.Posts
    ) {
        self.permissions = permissions
        self.commands = commands
    }
    
    func configure(_ app: Vapor.Application) async throws {
        app.migrations.add(AddPostAttachment())
        app.migrations.add(AddPostPublishedAt())
        app.migrations.add(AddPostLanguage())
        app.migrations.add(FixLanguageFieldValues())
        app.routes.defaultMaxBodySize = ByteCount(value: 1*1024*1024)
        app.databases.middleware.use(PostModelMiddleware())
        app.databases.middleware.use(DeletionMiddleware<Post>(
            deletionType: .post,
            itemID: { $0.id.map(String.init) },
            ownerID: { $0.$author.id },
            access: { $0.state == .published ? .public : .private }
        ))
        try await app.permissions.add(scope: permissions)
        try await app.commands.add(collection: commands)
    }
    
    func boot(_ routes: RoutesBuilder) async throws {
        try routes.register(collection: PostsAPIController())
        try routes
            .grouped(RecoverMiddleware())
            .register(collection: PostsWebController())
    }
}

extension Module where Self == Posts {
    static var posts: Self {
        Posts(
            permissions: PermissionScopes.Posts(),
            commands: Commands.Posts()
        )
    }
}
