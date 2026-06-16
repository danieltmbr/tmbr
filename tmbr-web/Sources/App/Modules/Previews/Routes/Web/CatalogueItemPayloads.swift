import Vapor
import CoreWeb
import CoreAuth
import CoreTmbr

// MARK: - Payload Types

struct CatalogueItemMetadataResponse: Content, Sendable {
    let title: String?
    let subtitle: String?
    let artworkURL: String?
}

struct CatalogueNewPayload: Decodable, Sendable {
    let url: String?
    let title: String
    let subtitle: String?
    let category: String
    let access: Access
    private let artworkIDRaw: String?
    private let artworkSourceURLRaw: String?
    let notes: [NotePayload]

    var artworkID: ImageID? {
        guard let raw = artworkIDRaw, !raw.isEmpty else { return nil }
        return Int(raw)
    }

    var artworkSourceURL: String? {
        guard let raw = artworkSourceURLRaw, !raw.isEmpty else { return nil }
        return raw
    }

    enum CodingKeys: String, CodingKey {
        case url
        case title
        case subtitle
        case category
        case access
        case artworkIDRaw = "artwork-id"
        case artworkSourceURLRaw = "artwork-source-url"
        case notes
    }
}
