import Foundation
import CoreTmbr

extension PreviewResponse {

    init(preview: Preview, baseURL: String, isNoteMatch: Bool = false, notes: [NoteResponse]? = nil) {
        let category = preview.catalogueCategory
        self.init(
            id: preview.id,
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
            isNoteMatch: isNoteMatch,
            notes: notes
        )
    }
}
