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

    public let primaryInfo: String

    public let secondaryInfo: String?

    public let image: ImageResponse?

    public let resources: [String]

    public let source: Source

    public let category: String?

    public let isNoteMatch: Bool

    public init(
        primaryInfo: String,
        secondaryInfo: String?,
        image: ImageResponse?,
        resources: [String],
        source: Source,
        category: String? = nil,
        isNoteMatch: Bool = false
    ) {
        self.primaryInfo = primaryInfo
        self.secondaryInfo = secondaryInfo
        self.image = image
        self.resources = resources
        self.source = source
        self.category = category
        self.isNoteMatch = isNoteMatch
    }
}
