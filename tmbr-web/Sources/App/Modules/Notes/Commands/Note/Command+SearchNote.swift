import Foundation
import Vapor
import Core
import Logging
import Fluent
import AuthKit
import TmbrCore

extension Command where Self == PlainCommand<NoteQueryPayload, [Note]> {
    static func searchNote(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Note>>
    ) -> Self {
        PlainCommand { input in
            guard let term = input.term?.trimmed, !term.isEmpty else {
                return []
            }
            let query = Note
                .query(on: database)
                .join(Preview.self, on: \Note.$attachment.$id == \Preview.$id)
                .with(\.$attachment) { preview in
                    preview
                        .with(\.$image)
                        .with(\.$catalogueCategory)
                }
                .with(\.$author)
                .with(\.$quotes)
                .filter(\.$language ~~? input.languages.map { $0.compactMap(Language.init(rawValue:)) })
                .group(.or) { group in
                    let sql = "body ILIKE '%\(term.replacingOccurrences(of: "'", with: "''"))%'"
                    group.filter(.sql(unsafeRaw: sql))
                }
                .sort(\Note.$createdAt, .descending)
            if let categoryIDs = input.categoryIDs {
                query.filter(Preview.self, \.$catalogueCategory.$id ~~ categoryIDs)
            }
            if let categorySlug = input.categorySlug {
                query
                    .join(CatalogueCategory.self, on: \CatalogueCategory.$id == \Preview.$catalogueCategory.$id)
                    .filter(CatalogueCategory.self, \.$slug == categorySlug)
            }
            try await permission.grant(query)
            return try await query.all()
        }
    }
}

extension CommandFactory<NoteQueryPayload, [Note]> {
    
    static var searchNote: Self {
        CommandFactory { request in
            .searchNote(
                database: request.commandDB,
                permission: request.permissions.notes.query
            )
            .logged(
                name: "Search Note",
                logger: request.logger
            )
        }
    }
}
