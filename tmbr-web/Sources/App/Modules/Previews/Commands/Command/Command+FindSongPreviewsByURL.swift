import Foundation
import Vapor
import Core
import Fluent
import AuthKit
import TmbrCore

struct FindSongPreviewsByURLInput: Sendable {
    let ownerID: UserID
}

extension Command where Self == PlainCommand<FindSongPreviewsByURLInput, [String: PreviewID]> {

    static func findSongPreviewsByURL(database: Database) -> Self {
        PlainCommand { input in
            guard let songCategory = try await CatalogueCategory.query(on: database)
                .filter(\.$slug == "song").first(),
                  let songCategoryID = songCategory.id else { return [:] }
            let songPreviews = try await Preview.query(on: database)
                .filter(\Preview.$catalogueCategory.$id == songCategoryID)
                .filter(\Preview.$parentOwner.$id == input.ownerID)
                .all()
            var result: [String: PreviewID] = [:]
            for preview in songPreviews {
                guard let id = preview.id else { continue }
                for link in preview.externalLinks { result[link] = id }
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
