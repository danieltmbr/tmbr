import Fluent

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .id()
            .field("apple_id", .string, .required)
            .field("name", .string, .required)
            .field("role", .string, .required, .custom("DEFAULT 'standard'"))
            .unique(on: "apple_id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users").delete()
    }
}
