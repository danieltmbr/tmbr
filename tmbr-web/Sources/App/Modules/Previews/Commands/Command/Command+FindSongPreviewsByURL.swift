import Foundation
import Vapor
import Core
import Fluent
import SQLKit
import AuthKit
import TmbrCore

struct FindSongPreviewsByURLInput: Sendable {
    let ownerID: UserID
    /// The track URLs to match against. Empty → returns [:] without querying.
    let urls: [String]
}

// Minimal row type for the SQLKit query — lives at file scope because Swift
// disallows nested type declarations inside closures in generic contexts.
private struct SongURLRow: Decodable {
    let id: UUID
    let externalLinks: [String]
    enum CodingKeys: String, CodingKey {
        case id
        case externalLinks = "external_links"
    }
}

extension Command where Self == PlainCommand<FindSongPreviewsByURLInput, [String: PreviewID]> {

    static func findSongPreviewsByURL(database: Database) -> Self {
        PlainCommand { input in
            guard !input.urls.isEmpty else { return [:] }
            guard let songCategory = try await CatalogueCategory.query(on: database)
                .filter(\.$slug == "song").first(),
                  let songCategoryID = songCategory.id else { return [:] }

            let urlSet = Set(input.urls)

            // Filter at the DB level using PostgreSQL's && (array overlap) operator so we
            // only load previews whose external_links share at least one URL with the input set.
            // Falls back to a full owner-scoped load for non-PostgreSQL databases (e.g. tests).
            if let sqlDB = database as? SQLDatabase {
                let rows = try await sqlDB.raw("""
                    SELECT id, external_links
                    FROM previews
                    WHERE category_id = \(bind: songCategoryID)
                      AND parent_owner = \(bind: input.ownerID)
                      AND external_links && \(bind: input.urls)::text[]
                    """).all(decoding: SongURLRow.self)
                var result: [String: PreviewID] = [:]
                for row in rows {
                    for link in row.externalLinks where urlSet.contains(link) {
                        result[link] = row.id
                    }
                }
                return result
            }

            let matchedPreviews = try await Preview.query(on: database)
                .filter(\.$catalogueCategory.$id == songCategoryID)
                .filter(\.$parentOwner.$id == input.ownerID)
                .all()
            var result: [String: PreviewID] = [:]
            for preview in matchedPreviews {
                guard let id = preview.id else { continue }
                for link in preview.externalLinks where urlSet.contains(link) {
                    result[link] = id
                }
            }
            return result
        }
    }
}

extension CommandFactory<FindSongPreviewsByURLInput, [String: PreviewID]> {

    static var findSongPreviewsByURL: Self {
        CommandFactory { request in
            .findSongPreviewsByURL(database: request.commandDB)
        }
    }
}
