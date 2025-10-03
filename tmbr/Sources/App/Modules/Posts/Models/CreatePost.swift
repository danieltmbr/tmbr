import Fluent

struct CreatePost: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("posts")
            .field("id", .int, .identifier(auto: true))
            .field("title", .string, .required)
            .field("content", .string, .required)
            .field("created_at", .datetime)
            .field("state", .string, .required)
            .field("author_id", .int, .required, .references("users", "id", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("posts").delete()
    }
}
