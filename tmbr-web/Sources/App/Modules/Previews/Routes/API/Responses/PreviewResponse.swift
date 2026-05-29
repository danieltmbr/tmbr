import Foundation
import TmbrCore

extension PreviewResponse {

    init(preview: Preview, baseURL: String, isNoteMatch: Bool = false) {
        let category = preview.catalogueCategory
        self.init(
            primaryInfo: preview.primaryInfo,
            secondaryInfo: preview.secondaryInfo,
            image: preview.image.map { image in
                ImageResponse(image: image, baseURL: baseURL)
            },
            resources: preview.externalLinks,
            source: Source(
                id: preview.parentID,
                type: category?.slug ?? "item"
            ),
            category: category?.kind == .orphan ? category?.slug : nil,
            isNoteMatch: isNoteMatch
        )
    }
}
