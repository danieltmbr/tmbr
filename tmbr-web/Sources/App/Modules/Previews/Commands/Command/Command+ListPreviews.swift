import Foundation
import Vapor
import CoreWeb
import Logging
import Fluent
import CoreAuth
import CoreTmbr

struct PreviewQueryInput: Sendable {

    let term: String?

    let categoryIDs: Set<Int>?

    let kind: CatalogueCategoryKind?

    let since: Date?

    let before: Date?

    let limit: Int?

    init(
        term: String? = nil,
        categoryIDs: Set<Int>? = nil,
        kind: CatalogueCategoryKind? = nil,
        since: Date? = nil,
        before: Date? = nil,
        limit: Int? = nil
    ) {
        self.term = term
        self.categoryIDs = categoryIDs
        self.kind = kind
        self.since = since
        self.before = before
        self.limit = limit
    }
}

extension Command where Self == PlainCommand<PreviewQueryInput, [Preview]> {

    static func listPreviews(
        database: Database,
        permission: BasePermissionResolver<QueryBuilder<Preview>>
    ) -> Self {
        PlainCommand { input in
            let query = Preview.query(on: database)
                .with(\.$parentOwner)
                .sort(\.$createdAt, .descending)
                .with(\.$image)
                .with(\.$catalogueCategory)

            if let kind = input.kind {
                query
                    .join(CatalogueCategory.self, on: \Preview.$catalogueCategory.$id == \CatalogueCategory.$id)
                    .filter(CatalogueCategory.self, \.$kind == kind)
            }
            if let categoryIDs = input.categoryIDs {
                query.filter(\.$catalogueCategory.$id ~~ categoryIDs)
            }
            if let term = input.term, !term.isEmpty {
                query.group(.or) { group in
                    group.filter(\.$primaryInfo, .custom("ILIKE"), "%\(term)%")
                    group.filter(\.$secondaryInfo, .custom("ILIKE"), "%\(term)%")
                }
            }
            // Delta (`since`) matches items created OR whose notes changed since last sync — note
            // edits bump updatedAt (see NoteModelMiddleware). Load-more (`before`) stays on createdAt.
            if let since = input.since {
                query.group(.or) { or in
                    or.filter(\.$createdAt > since)
                    or.filter(\.$updatedAt > since)
                }
            }
            if let before = input.before { query.filter(\.$createdAt < before) }
            if let limit = input.limit { query.limit(limit) }
            try await permission.grant(query)
            return try await query.all()
        }
    }
}

extension CommandFactory<PreviewQueryInput, [Preview]> {

    static var listPreviews: Self {
        CommandFactory { request in
            .listPreviews(
                database: request.commandDB,
                permission: request.permissions.previews.query
            )
            .logged(
                name: "List previews",
                logger: request.logger
            )
        }
    }
}
