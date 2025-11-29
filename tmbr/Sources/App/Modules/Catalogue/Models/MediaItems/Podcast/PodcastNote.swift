import Fluent
import Vapor
import Foundation

final class PodcastNote: Model, @unchecked Sendable {
    static let schema = "podcast_notes"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Parent(key: "note_id")
    var note: Note

    @Parent(key: "podcast_id")
    var podcast: Podcast
}
