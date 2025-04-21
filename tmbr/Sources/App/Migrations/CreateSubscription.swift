import Fluent

struct CreateSubscription: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("subscriptions")
            .id()
            .field("endpoint", .string, .required)
            .field("p256dh", .string, .required)
            .field("auth", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("subscriptions").delete()
    }
}
