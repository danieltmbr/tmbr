import Foundation
import Vapor
import Core
import Fluent
import AuthKit
import TmbrCore

struct UpdatePreviewItemInput: Sendable {
    let previewID: PreviewID
    let title: String
    let subtitle: String?
    let artworkID: ImageID?
    let externalLink: String?
    let categoryName: String
}

extension Command where Self == PlainCommand<UpdatePreviewItemInput, Preview> {

    static func updatePreviewItem(database: Database) -> Self {
        PlainCommand { input in
            guard let preview = try await Preview.find(input.previewID, on: database) else {
                throw Abort(.notFound)
            }

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

            preview.primaryInfo = input.title
            preview.secondaryInfo = input.subtitle
            preview.externalLinks = [input.externalLink].compactMap { $0 }
            preview.$catalogueCategory.id = category.id
            if let artworkID = input.artworkID {
                preview.$image.id = artworkID
            }
            try await preview.save(on: database)
            preview.$catalogueCategory.value = category
            return preview
        }
    }
}

extension CommandFactory<UpdatePreviewItemInput, Preview> {

    static var updatePreviewItem: Self {
        CommandFactory { request in
            .updatePreviewItem(database: request.commandDB)
            .logged(name: "Update preview item", logger: request.logger)
        }
    }
}
