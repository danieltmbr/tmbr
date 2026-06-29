import Foundation
import Vapor
import WebCore
import Fluent

struct DeleteContainerEntriesInput: Sendable {
    let containerType: String
    let containerID: Int
}

extension Command where Self == PlainCommand<DeleteContainerEntriesInput, Void> {
    static func deleteContainerEntries(database: Database) -> Self {
        PlainCommand { input in
            let entries = try await ContainerEntry.query(on: database)
                .filter(\.$containerType == input.containerType)
                .filter(\.$containerID == input.containerID)
                .with(\.$preview) { $0.with(\.$catalogueCategory) }
                .all()

            for entry in entries {
                if entry.preview.catalogueCategory?.kind == .promotable {
                    // Deleting the preview cascades to delete the ContainerEntry via FK
                    try await entry.preview.delete(on: database)
                } else {
                    // Preview was promoted to a real catalogue item — keep the preview, only remove the entry
                    try await entry.delete(on: database)
                }
            }
        }
    }
}

extension CommandFactory<DeleteContainerEntriesInput, Void> {
    static var deleteContainerEntries: Self {
        CommandFactory { request in
            .deleteContainerEntries(database: request.commandDB)
        }
    }
}
