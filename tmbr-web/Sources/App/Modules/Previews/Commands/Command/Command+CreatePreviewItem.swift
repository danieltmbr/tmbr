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
    let category: String
    let ownerID: UserID
}

extension Command where Self == PlainCommand<CreatePreviewItemInput, Preview> {

    static func createPreviewItem(database: Database) -> Self {
        PlainCommand { input in
            let preview = Preview(
                id: UUID(),
                parentID: nil,
                parentAccess: input.access,
                parentOwner: input.ownerID,
                parentType: input.category
            )
            preview.primaryInfo = input.title
            preview.secondaryInfo = input.subtitle
            preview.externalLinks = [input.externalLink].compactMap { $0 }
            if let artworkID = input.artworkID {
                preview.$image.id = artworkID
            }
            try await preview.save(on: database)
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
