import Foundation
import Vapor
import CoreWeb
import Fluent
import CoreAuth
import CoreTmbr

struct UpdatePreviewItemInput: Sendable {
    let previewID: PreviewID
    let title: String
    let subtitle: String?
    let artworkID: ImageID?
    let externalLink: String?
    let categoryName: String
}

struct UpdatePreviewItemCommand: Command {

    typealias Input = UpdatePreviewItemInput
    typealias Output = Preview

    private let findCategory: CommandResolver<String, CatalogueCategory?>
    private let createCategory: CommandResolver<String, CatalogueCategory>
    private let database: Database

    init(
        findCategory: CommandResolver<String, CatalogueCategory?>,
        createCategory: CommandResolver<String, CatalogueCategory>,
        database: Database
    ) {
        self.findCategory = findCategory
        self.createCategory = createCategory
        self.database = database
    }

    func execute(_ input: UpdatePreviewItemInput) async throws -> Preview {
        guard let preview = try await Preview.find(input.previewID, on: database) else {
            throw Abort(.notFound)
        }
        let slug = input.categoryName.categorySlug
        guard !slug.isEmpty else {
            throw Abort(.badRequest, reason: "Category name is required")
        }
        let category: CatalogueCategory
        if let existing = try await findCategory(slug) {
            category = existing
        } else {
            category = try await createCategory(input.categoryName)
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

extension CommandFactory<UpdatePreviewItemInput, Preview> {

    static var updatePreviewItem: Self {
        CommandFactory { request in
            UpdatePreviewItemCommand(
                findCategory: request.commands.catalogueCategories.find,
                createCategory: request.commands.catalogueCategories.create,
                database: request.commandDB
            )
            .logged(name: "Update preview item", logger: request.logger)
        }
    }
}
