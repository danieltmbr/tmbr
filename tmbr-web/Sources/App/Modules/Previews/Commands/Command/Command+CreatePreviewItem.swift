import Foundation
import Vapor
import Core
import Fluent
import AuthKit
import TmbrCore

struct CreatePreviewItemInput: Sendable {
    let title: String
    let subtitle: String?
    let access: Access
    let artworkID: ImageID?
    let externalLink: String?
    let categoryName: String
    let ownerID: UserID
}

extension Command where Self == PlainCommand<CreatePreviewItemInput, Preview> {

    static func createPreviewItem(database: Database) -> Self {
        PlainCommand { input in
            let name = input.categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
            let slug = name
                .lowercased()
                .components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            let resolvedSlug = slug.isEmpty ? "link" : slug
            let resolvedName = name.isEmpty ? "Link" : name

            let category: CatalogueCategory
            if let existing = try await CatalogueCategory.query(on: database)
                .filter(\.$slug == resolvedSlug)
                .first() {
                category = existing
            } else {
                category = CatalogueCategory(slug: resolvedSlug, name: resolvedName, kind: .orphan)
                try await category.create(on: database)
            }

            let preview = Preview(
                id: UUID(),
                parentID: nil,
                parentAccess: input.access,
                parentOwner: input.ownerID,
                categoryID: category.id
            )
            preview.primaryInfo = input.title
            preview.secondaryInfo = input.subtitle
            preview.externalLinks = [input.externalLink].compactMap { $0 }
            if let artworkID = input.artworkID {
                preview.$image.id = artworkID
            }
            try await preview.save(on: database)
            preview.$catalogueCategory.value = category
            return preview
        }
    }
}

extension CommandFactory<CreatePreviewItemInput, Preview> {

    static var createPreviewItem: Self {
        CommandFactory { request in
            .createPreviewItem(database: request.commandDB)
            .logged(name: "Create preview item", logger: request.logger)
        }
    }
}
