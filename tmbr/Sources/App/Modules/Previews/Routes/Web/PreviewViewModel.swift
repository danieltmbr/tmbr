import Foundation

struct PreviewViewModel: Encodable, Sendable {

    let primaryInfo: String

    let secondaryInfo: String?

    let thumbnailURL: String?

    let href: String
    
    let created: String

    init(preview: Preview, baseURL: String) {
        primaryInfo = preview.primaryInfo
        secondaryInfo = preview.secondaryInfo
        thumbnailURL = preview.image.map { "\(baseURL)/gallery/data/\($0.thumbnailKey)" }
        href = "/\(preview.parentType)s/\(preview.parentID)"
        created = (preview.createdAt ?? .now).formatted(.publishDate)
    }
}
