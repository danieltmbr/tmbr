import Fluent

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users")
            .field("id", .int, .identifier(auto: true))
            .field("apple_id", .string, .required)
            .field("email", .string)
            .field("first_name", .string)
            .field("last_name", .string)
            .field("role", .string, .required, .custom("DEFAULT 'standard'"))
            .unique(on: "apple_id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users").delete()
    }
}
