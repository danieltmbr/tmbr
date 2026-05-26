import Fluent
import Foundation
import AuthKit

struct CreatePodcast: AsyncMigration {
    func prepare(on database: Database) async throws {
        let accessType = try await database.enum("access").read()

        try await database.schema(Podcast.schema)
            .field("id", .int, .identifier(auto: true))
            .field("access", accessType, .required)
            .field("artwork_id", .int)
            .field("owner_id", .int, .required)
            .field("post_id", .int)
            .field("preview_id", .uuid, .required)
            .field("release_date", .datetime)
            .field("resource_urls", .array(of: .string), .required, .sql(.default("{}")))
            .field("title", .string, .required)
            .foreignKey("artwork_id", references: Image.schema, "id", onDelete: .setNull)
            .foreignKey("owner_id", references: User.schema, "id", onDelete: .cascade)
            .foreignKey("post_id", references: Post.schema, "id", onDelete: .setNull)
            .foreignKey("preview_id", references: Preview.schema, "id", onDelete: .cascade)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Podcast.schema).delete()
    }
}

