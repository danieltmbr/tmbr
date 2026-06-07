import Fluent
import Foundation
import SQLKit

struct AddWebPushSubscriptionContentTypes: AsyncMigration {
    func prepare(on database: Database) async throws {
        guard let sqlDB = database as? SQLDatabase else { return }
        try await sqlDB.raw("""
            ALTER TABLE web_push_subscriptions
            ADD COLUMN IF NOT EXISTS content_types TEXT NOT NULL DEFAULT ''
            """).run()
        // Existing subscribers get posts-only so behaviour is unchanged.
        try await sqlDB.raw("""
            UPDATE web_push_subscriptions
            SET content_types = 'post'
            WHERE content_types = ''
            """).run()
    }

    func revert(on database: Database) async throws {
        try await database.schema(WebPushSubscription.schema)
            .deleteField("content_types")
            .update()
    }
}
