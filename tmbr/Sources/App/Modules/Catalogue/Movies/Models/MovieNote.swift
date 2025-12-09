import Fluent
import Vapor
import Foundation

final class MovieNote: Model, @unchecked Sendable {
    static let schema = "moive_notes"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Parent(key: "moive_id")
    private(set) var movie: Movie

    @Parent(key: "note_id")
    private(set) var note: Note
    
    init() {}
    
    init(movie: MovieID, note: NoteID) {
        self.$movie.id = movie
        self.$note.id = note
    }
}
