import Fluent
import Vapor
import Core

struct Posts: Module {
    
    private let permissions: PermissionScopes.Posts
    
    init(permissions: PermissionScopes.Posts) {
        self.permissions = permissions
    }
    
    func configure(_ app: Vapor.Application) async throws {
        app.migrations.add(CreatePost())
        try await app.permissions.add(scope: permissions)
    }
    
    func boot(_ routes: RoutesBuilder) async throws {
        try routes.register(collection: PostsAPIController())
        try routes.register(collection: PostsWebController())
    }
}

extension Module where Self == Posts {
    static var posts: Self {
        Posts(permissions: PermissionScopes.Posts(
            access: .accessPost,
            create: .createPost,
            delete: .deletePost,
            edit: .editPost
        ))
    }
}
