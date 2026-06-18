import Foundation
import Vapor
import CoreWeb
import Fluent

struct ContainerEntryInput: Sendable {
    let previewID: UUID
    let containerType: String?

    init(previewID: UUID, containerType: String? = nil) {
        self.previewID = previewID
        self.containerType = containerType
    }
}

extension Command where Self == PlainCommand<ContainerEntryInput, ContainerEntry> {
    static func fetchContainerEntry(database: Database) -> Self {
        PlainCommand { input in
            var query = ContainerEntry.query(on: database)
                .filter(\.$preview.$id == input.previewID)
            if let type = input.containerType {
                query = query.filter(\.$containerType == type)
            }
            guard let entry = try await query.first() else {
                throw Abort(.notFound, reason: "No container entry found for this preview")
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
