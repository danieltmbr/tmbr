import Fluent
import Vapor
import Foundation

final class SongNote: Model, @unchecked Sendable {
    static let schema = "song_notes"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Parent(key: "note_id")
    var note: Note
    
    @Parent(key: "song_id")
    var song: Song
}
