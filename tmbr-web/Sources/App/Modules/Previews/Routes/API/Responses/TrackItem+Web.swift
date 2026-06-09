import Foundation
import TmbrCore

extension TrackItem {

    init?(preview: Preview, position: Int) {
        guard let previewID = preview.id?.uuidString else { return nil }
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
            previewID: previewID,
            trackURL: preview.externalLinks.first
        )
    }
}
