import Foundation
import Vapor
import Core
import Fluent
import AuthKit
import TmbrCore

struct FindSongPreviewsByURLInput: Sendable {
    let ownerID: UserID
    /// The track URLs to match against. Empty → returns [:] without querying.
    let urls: [String]
}

struct FindSongPreviewsByURLCommand: Command {

    typealias Input = FindSongPreviewsByURLInput
    typealias Output = [String: Preview]

    private let findCategory: CommandResolver<String, CatalogueCategory?>
    private let database: Database

    init(
        findCategory: CommandResolver<String, CatalogueCategory?>,
        database: Database
    ) {
        self.findCategory = findCategory
        self.database = database
    }

    func execute(_ input: FindSongPreviewsByURLInput) async throws -> [String: Preview] {
        guard !input.urls.isEmpty else { return [:] }
        guard let songCategory = try await findCategory("song"),
              let songCategoryID = songCategory.id else {
            throw Abort(.internalServerError, reason: "Catalogue category 'song' not found")
        }
        let urlSet = Set(input.urls)
        let previews = try await Preview.query(on: database)
            .filter(\.$catalogueCategory.$id == songCategoryID)
            .filter(\.$parentOwner.$id == input.ownerID)
            .filter(\.$externalLinks, .custom("&&"), input.urls)
            .all()
        var result: [String: Preview] = [:]
        for preview in previews {
            for link in preview.externalLinks where urlSet.contains(link) {
                result[link] = preview
            }
        }
        return result
    }
}

extension CommandFactory<FindSongPreviewsByURLInput, [String: Preview]> {

    static var findSongPreviewsByURL: Self {
        CommandFactory { request in
            FindSongPreviewsByURLCommand(
                findCategory: request.commands.catalogueCategories.find,
                database: request.commandDB
            )
        }
    }
}
