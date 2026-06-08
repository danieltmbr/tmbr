import Foundation
import TmbrCore

extension TrackItem {

    init(preview: Preview, position: Int, notes: [Note], baseURL: String) {
        let href: String?
        if let parentID = preview.parentID, let route = preview.catalogueCategory?.route {
            href = "/\(route)/\(parentID)"
        } else {
            href = nil
        }
        self.init(
            position: position,
            title: preview.primaryInfo,
            href: href,
            previewID: preview.id!.uuidString,
            trackURL: preview.externalLinks.first,
            notes: notes.map { NoteResponse(note: $0, baseURL: baseURL) }
        )
    }
}
