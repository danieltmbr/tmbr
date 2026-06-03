import Foundation
import TmbrCore

extension PreviewResponse {

    init(preview: Preview, baseURL: String, isNoteMatch: Bool = false) {
        self.init(
            primaryInfo: preview.primaryInfo,
            secondaryInfo: preview.secondaryInfo,
            image: preview.image.map { image in
                ImageResponse(image: image, baseURL: baseURL)
            },
            resources: preview.externalLinks,
            source: Source(
                id: preview.parentID,
                type: preview.parentType ?? preview.category ?? "item"
            ),
            category: preview.category,
            isNoteMatch: isNoteMatch
        )
    }
}
