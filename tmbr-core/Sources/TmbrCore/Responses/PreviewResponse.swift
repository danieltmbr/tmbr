import Foundation

public struct PreviewResponse: Codable, Sendable {

    public struct Source: Codable, Sendable {
        public let id: Int?

        public let type: String

        public init(id: Int?, type: String) {
            self.id = id
            self.type = type
        }
    }

    /// Stable cross-type identifier (Preview UUID). Optional only because a few synthesized previews
    /// (search/quote matches) have no backing row; catalogue sync responses always set it.
    public let id: PreviewID?

    public let primaryInfo: String

    public let secondaryInfo: String?

    public let image: ImageResponse?

    public let resources: [String]

    public let source: Source

    public let category: String?

    public let isNoteMatch: Bool

    /// Notes attached to this item. `nil` when not requested (lists omit them by default); populated
    /// when the endpoint is asked to embed notes (e.g. `?notes=true`).
    public let notes: [NoteResponse]?

    public init(
        id: PreviewID? = nil,
        primaryInfo: String,
        secondaryInfo: String?,
        image: ImageResponse?,
        resources: [String],
        source: Source,
        category: String? = nil,
        isNoteMatch: Bool = false,
        notes: [NoteResponse]? = nil
    ) {
        self.id = id
        self.primaryInfo = primaryInfo
        self.secondaryInfo = secondaryInfo
        self.image = image
        self.resources = resources
        self.source = source
        self.category = category
        self.isNoteMatch = isNoteMatch
        self.notes = notes
    }
}
