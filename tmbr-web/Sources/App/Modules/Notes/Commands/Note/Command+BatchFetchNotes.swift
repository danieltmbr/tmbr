import CoreWeb
import Fluent
import CoreAuth
import CoreTmbr

struct GroupedNotesInput: Sendable {
    let previewIDs: [PreviewID]
}

extension Command where Self == PlainCommand<GroupedNotesInput, [PreviewID: [Note]]> {

    static func groupedNotes(database: Database, permission: BasePermissionResolver<QueryBuilder<Note>>) -> Self {
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

extension CommandFactory<GroupedNotesInput, [PreviewID: [Note]]> {

    static var groupedNotes: Self {
        CommandFactory { request in
            .groupedNotes(database: request.commandDB, permission: request.permissions.notes.query)
            .logged(name: "Grouped notes", logger: request.logger)
        }
    }
}

extension CommandResolver where Input == GroupedNotesInput {
    @Sendable
    func callAsFunction(_ previewIDs: [PreviewID]) async throws -> Output {
        try await self.callAsFunction(GroupedNotesInput(previewIDs: previewIDs))
    }
}
