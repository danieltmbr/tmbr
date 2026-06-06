import Fluent
import Foundation
import SQLKit

struct AddWebPushSubscriptionLanguages: AsyncMigration {
    func prepare(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }
        try await sqlDB.raw("ALTER TABLE web_push_subscriptions ADD COLUMN IF NOT EXISTS languages TEXT NOT NULL DEFAULT ''").run()
    }

    func revert(on database: Database) async throws {
        try await database.schema(WebPushSubscription.schema)
            .deleteField("languages")
            .update()
    }
}
