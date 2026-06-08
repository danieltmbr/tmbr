import Foundation
import TmbrCore

/// Editor-layer track — carries an optional previewID for library songs added via search.
/// Distinct from TrackMetadata, which is a pure metadata-extraction result.
struct TrackEntry: Codable, Sendable {
    let name: String
    let url: String?
    let previewID: UUID?

    init(name: String, url: String?, previewID: UUID? = nil) {
        self.name = name
        self.url = url
        self.previewID = previewID
    }
}
