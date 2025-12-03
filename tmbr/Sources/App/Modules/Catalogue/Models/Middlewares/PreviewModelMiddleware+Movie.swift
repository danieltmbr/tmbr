import Fluent
import Vapor

extension PreviewModelMiddleware where M == Movie {
    
    static var movie: Self {
        Self(
            attach: { previewID, movie in
                movie.$preview.id = previewID
            },
            configure: { preview, movie in
                preview.primaryInfo = movie.title
                preview.secondaryInfo = movie.releaseDate?.formatted()
                preview.$image.id = movie.cover?.id
                preview.externalLinks = movie.resourceURLs
            },
            fetch: { movie, database in
                try await movie.$preview.load(on: database)
                return movie.preview
            }
        )
    }
}
