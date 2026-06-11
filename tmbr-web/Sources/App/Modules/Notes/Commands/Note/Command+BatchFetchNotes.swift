import Core
import Fluent
import AuthKit
import TmbrCore

struct BatchFetchNotesInput: Sendable {
    let previewIDs: [PreviewID]
}

extension Command where Self == PlainCommand<BatchFetchNotesInput, [PreviewID: [Note]]> {

    static func batchFetchNotes(database: Database, permission: BasePermissionResolver<QueryBuilder<Note>>) -> Self {
        PlainCommand { input in
            guard !input.previewIDs.isEmpty else { return [:] }
            let query = Note.query(on: database)
                .filter(\.$attachment.$id ~~ input.previewIDs)
                .with(\.$attachment) { a in a.with(\.$image) }
                .with(\.$author)
                .with(\.$quotes)
            try await permission.grant(query)
            let notes = try await query.all()
            return Dictionary(grouping: notes, by: { $0.$attachment.id })
        }
    }
}

extension CommandFactory<BatchFetchNotesInput, [PreviewID: [Note]]> {

    static var batchFetchNotes: Self {
        CommandFactory { request in
            .batchFetchNotes(database: request.commandDB, permission: request.permissions.notes.query)
            .logged(name: "Batch fetch notes", logger: request.logger)
        }
    }
}
