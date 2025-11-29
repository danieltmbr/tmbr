import Fluent
import Vapor

extension PreviewModelMiddleware where M == Song {
    
    static var song: Self {
        Self(
            attach: { previewID, song in
                song.$preview.id = previewID
            },
            configure: { preview, song in
                preview.primaryInfo = song.title
                preview.secondaryInfo = song.artist
                preview.$image.id = song.artwork?.id
                preview.externalLinks = song.resourceURLs
            },
            fetch: { song, database in
                try await song.$preview.load(on: database)
                return song.preview
            }
        )
    }
}
