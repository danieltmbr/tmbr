import Fluent
import Vapor

extension PreviewModelMiddleware where M == Podcast {
    
    static var podcast: Self {
        Self(
            attach: { previewID, podcast in
                podcast.$preview.id = previewID
            },
            configure: { preview, podcast in
                preview.primaryInfo = podcast.episodeTitle
                preview.secondaryInfo = podcast.title
                preview.$image.id = podcast.artwork?.id
                preview.externalLinks = podcast.resourceURLs
            },
            fetch: { podcast, database in
                try await podcast.$preview.load(on: database)
                return podcast.preview
            }
        )
    }
}
