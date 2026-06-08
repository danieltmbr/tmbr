import Foundation
import Vapor
import Core
import Fluent
import TmbrCore

extension Command where Self == PlainCommand<[PreviewID], [PreviewID: [Note]]> {

    static func fetchTrackNotes(database: Database) -> Self {
        PlainCommand { previewIDs in
            guard !previewIDs.isEmpty else { return [:] }
            let notes = try await Note.query(on: database)
                .group(.or) { group in previewIDs.forEach { group.filter(\.$attachment.$id == $0) } }
                .with(\.$attachment)
                .sort(\Note.$createdAt, .descending)
                .all()
            var result: [PreviewID: [Note]] = [:]
            for note in notes {
                result[note.$attachment.id, default: []].append(note)
            }
            return result
        }
    }
}

extension CommandFactory<[PreviewID], [PreviewID: [Note]]> {

    static var fetchTrackNotes: Self {
        CommandFactory { request in
            .fetchTrackNotes(database: request.commandDB)
        }
    }
}
