import Foundation
import Vapor
import Core
import Fluent

struct ContainerEntryInput: Sendable {
    let previewID: UUID
    let containerType: String
}

extension Command where Self == PlainCommand<ContainerEntryInput, ContainerEntry> {
    static func fetchContainerEntry(database: Database) -> Self {
        PlainCommand { input in
            guard let entry = try await ContainerEntry.query(on: database)
                .filter(\.$preview.$id == input.previewID)
                .filter(\.$containerType == input.containerType)
                .first()
            else {
                throw Abort(.notFound, reason: "No \(input.containerType) container entry found for this preview")
            }
            return entry
        }
    }
}

extension CommandFactory<ContainerEntryInput, ContainerEntry> {
    static var fetchContainerEntry: Self {
        CommandFactory { request in
            .fetchContainerEntry(database: request.commandDB)
        }
    }
}
