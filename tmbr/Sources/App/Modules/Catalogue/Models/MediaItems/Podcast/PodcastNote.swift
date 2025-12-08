import Fluent
import Vapor
import Foundation

final class PodcastNote: Model, @unchecked Sendable {
    static let schema = "podcast_notes"

    @ID(custom: "id", generatedBy: .database)
    var id: Int?
    
    @Parent(key: "note_id")
    private(set) var note: Note

    @Parent(key: "podcast_id")
    private(set) var podcast: Podcast
    
    init() {}
    
    init(note: NoteID, podcast: PodcastID) {
        self.$note.id = note
        self.$podcast.id = podcast
    }
}
