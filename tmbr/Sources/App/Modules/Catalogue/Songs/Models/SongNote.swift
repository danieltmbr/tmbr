import Fluent
import Vapor
import Foundation

final class SongNote: Model, @unchecked Sendable {
    static let schema = "song_notes"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Parent(key: "note_id")
    private(set) var note: Note
    
    @Parent(key: "song_id")
    private(set) var song: Song
    
    init() {}
    
    init(note: NoteID, song: SongID) {
        self.$note.id = note
        self.$song.id = song
    }
}
