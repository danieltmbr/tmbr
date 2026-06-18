import Foundation
import Vapor
import CoreWeb
import Fluent

extension Command where Self == PlainCommand<ContainerEntriesInput, [Preview]> {
    static func listContainerPreviews(database: Database) -> Self {
        PlainCommand { input in
            try await Preview.query(on: database)
                .join(ContainerEntry.self, on: \Preview.$id == \ContainerEntry.$preview.$id)
                .filter(ContainerEntry.self, \.$containerType == input.containerType)
                .filter(ContainerEntry.self, \.$containerID == input.containerID)
                .sort(ContainerEntry.self, \.$position)
                .with(\.$catalogueCategory)
                .all()
        }
    }
}

extension CommandFactory<ContainerEntriesInput, [Preview]> {
    static var listContainerPreviews: Self {
        CommandFactory { request in
            .listContainerPreviews(database: request.commandDB)
        }
    }
}

extension CommandResolver where Input == ContainerEntriesInput {
    func callAsFunction(_ containerType: String, _ containerID: Int) async throws -> Output {
        try await callAsFunction(ContainerEntriesInput(containerType: containerType, containerID: containerID))
    }
}
