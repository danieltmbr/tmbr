import Fluent
import Vapor
import Foundation

final class MovieNote: Model, @unchecked Sendable {
    static let schema = "moive_notes"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?

    @Parent(key: "moive_id")
    var movie: Movie

    @Parent(key: "note_id")
    var note: Note
}
