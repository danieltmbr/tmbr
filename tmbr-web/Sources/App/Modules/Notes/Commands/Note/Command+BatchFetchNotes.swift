import Core
import Fluent
import AuthKit
import TmbrCore

struct BatchFetchNotesInput: Sendable {
    let previewIDs: [PreviewID]
}

extension Command where Self == PlainCommand<BatchFetchNotesInput, [PreviewID: [Note]]> {

    static func batchFetchNotes(database: Database, permission: AuthPermissionResolver<Void>) -> Self {
        PlainCommand { input in
            let user = try await permission.grant()
            guard !input.previewIDs.isEmpty else { return [:] }
            let notes = try await Note.query(on: database)
                .filter(\.$attachment.$id ~~ input.previewIDs)
                .filter(\.$author.$id == user.userID)
                .with(\.$attachment) { a in a.with(\.$image) }
                .with(\.$author)
                .with(\.$quotes)
                .all()
            return Dictionary(grouping: notes, by: { $0.$attachment.id })
        }
    }
}

extension CommandFactory<BatchFetchNotesInput, [PreviewID: [Note]]> {

    static var batchFetchNotes: Self {
        CommandFactory { request in
            .batchFetchNotes(database: request.commandDB, permission: request.permissions.notes.list)
            .logged(name: "Batch fetch notes", logger: request.logger)
        }
    }
}
