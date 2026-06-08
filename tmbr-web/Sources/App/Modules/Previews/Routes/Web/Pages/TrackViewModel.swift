import Foundation

struct TrackViewModel: Encodable, Sendable {
    let position: Int
    let title: String
    let href: String?
    let previewID: String?
    let trackURL: String?
    let notes: [NoteViewModel]

    init(preview: Preview, position: Int, notes: [NoteViewModel] = []) {
        self.position = position
        title = preview.primaryInfo
        trackURL = preview.externalLinks.first
        self.notes = notes
        if let parentID = preview.parentID, let route = preview.catalogueCategory?.route {
            href = "/\(route)/\(parentID)"
            previewID = preview.id?.uuidString
        } else {
            href = nil
            previewID = preview.id?.uuidString
        }
    }
}
