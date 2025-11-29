import Fluent
import Vapor
import Foundation

final class MusicNote: Model, @unchecked Sendable {
    static let schema = "music_notes"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Parent(key: "music_id")
    var music: Music

    @Parent(key: "note_id")
    var note: Note
}
