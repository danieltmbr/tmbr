import Foundation

struct TrackViewModel: Encodable, Sendable {
    let position: Int
    let title: String
    let href: String?
    let previewID: String?
    let trackURL: String?

    init(preview: Preview, position: Int) {
        self.position = position
        title = preview.primaryInfo
        trackURL = preview.externalLinks.first
        if let parentID = preview.parentID, let route = preview.catalogueCategory?.route {
            href = "/\(route)/\(parentID)"
            previewID = preview.id?.uuidString
        } else {
            href = nil
            previewID = preview.id?.uuidString
        }
    }

    init(name: String, position: Int, url: String? = nil) {
        self.position = position
        self.title = name
        self.href = nil
        self.previewID = nil
        self.trackURL = url
    }
}
