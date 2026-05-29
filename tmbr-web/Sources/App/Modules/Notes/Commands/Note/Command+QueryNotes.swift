import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit
import TmbrCore

struct QueryNotesInput: Sendable {
    let ownerID: Int

    let ownerType: String

    let languages: Set<String>?

    init(ownerID: Int, ownerType: String, languages: Set<String>? = nil) {
        self.ownerID = ownerID
        self.ownerType = ownerType
        self.languages = languages
    }
}

extension Command where Self == PlainCommand<QueryNotesInput, [Note]> {
    
    static func queryNotes(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Note>>
    ) -> Self {
        PlainCommand { input in
            let languages = input.languages?.compactMap(Language.init(rawValue:))
            let query = Note
                .query(on: database)
                .join(Preview.self, on: \Note.$attachment.$id == \Preview.$id)
                .join(CatalogueCategory.self, on: \CatalogueCategory.$id == \Preview.$catalogueCategory.$id)
                .filter(CatalogueCategory.self, \.$slug == input.ownerType)
                .filter(Preview.self, \.$parentID == input.ownerID)
                .languages(languages)
                .with(\.$attachment) { attachment in
                    attachment.with(\.$image)
                }
                .sort(\Note.$createdAt, .descending)
            try await permission.grant(query)
            return try await query.all()
        }
    }
}

extension CommandFactory<QueryNotesInput, [Note]> {
    
    static var queryNotes: Self {
        CommandFactory { request in
            .queryNotes(
                database: request.commandDB,
                permission: request.permissions.notes.query
            )
            .logged(
                name: "Query notes",
                logger: request.logger
            )
        }
    }
}

extension CommandResolver where Input == QueryNotesInput {

    func callAsFunction(id: Int, of type: String, languages: Set<String>? = nil) async throws -> Output {
        try await callAsFunction(QueryNotesInput(ownerID: id, ownerType: type, languages: languages))
    }

    func callAsFunction<Item: Previewable>(for item: Item, languages: Set<String>? = nil) async throws -> Output {
        try await callAsFunction(id: item.requireID(), of: Item.previewType, languages: languages)
    }
}
