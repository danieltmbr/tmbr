import Foundation
import Vapor
import WebCore
import Fluent

struct ContainerEntriesInput: Sendable {
    let containerType: String
    let containerID: Int
}

extension Command where Self == PlainCommand<ContainerEntriesInput, [ContainerEntry]> {
    static func listContainerEntries(database: Database) -> Self {
        PlainCommand { input in
            try await ContainerEntry.query(on: database)
                .filter(\.$containerType == input.containerType)
                .filter(\.$containerID == input.containerID)
                .sort(\.$position)
                .with(\.$preview) { $0.with(\.$catalogueCategory) }
                .all()
        }
    }
}

extension CommandFactory<ContainerEntriesInput, [ContainerEntry]> {
    static var listContainerEntries: Self {
        CommandFactory { request in
            .listContainerEntries(database: request.commandDB)
        }
    }
}
