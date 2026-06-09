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

struct CreatePreviewItemCommand: Command {

    typealias Input = CreatePreviewItemInput
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

    func execute(_ input: CreatePreviewItemInput) async throws -> Preview {
        let slug = input.categoryName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        guard !slug.isEmpty else {
            throw Abort(.badRequest, reason: "Category name is required")
        }
        let category: CatalogueCategory
        if let existing = try await findCategory(slug) {
            category = existing
        } else {
            category = try await createCategory(input.categoryName)
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

extension CommandFactory<CreatePreviewItemInput, Preview> {

    static var createPreviewItem: Self {
        CommandFactory { request in
            CreatePreviewItemCommand(
                findCategory: request.commands.catalogueCategories.find,
                createCategory: request.commands.catalogueCategories.create,
                database: request.commandDB
            )
            .logged(name: "Create preview item", logger: request.logger)
        }
    }
}
