import Fluent

struct CreateWebPushSubscription: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("web_push_subscriptions")
            .id()
            .field("endpoint", .string, .required)
            .field("p256dh", .string, .required)
            .field("auth", .string, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("web_push_subscriptions").delete()
    }
}
