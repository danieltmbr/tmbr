import Foundation

public struct TrackItem: Codable, Sendable {

    public let position: Int

    public let title: String

    /// Route to the promoted song page (e.g. `/songs/123`). Non-nil only when the track has been promoted.
    public let href: String?

    /// UUID of the preview backing this tracklist entry. Stable through promotion.
    public let previewID: String

    public let trackURL: String?

    public init(
        position: Int,
        title: String,
        href: String?,
        previewID: String,
        trackURL: String?
    ) {
        self.position = position
        self.title = title
        self.href = href
        self.previewID = previewID
        self.trackURL = trackURL
    }
}
