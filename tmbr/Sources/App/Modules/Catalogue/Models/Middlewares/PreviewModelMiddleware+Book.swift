import Fluent
import Vapor

extension PreviewModelMiddleware where M == Book {
    
    static var book: Self {
        Self(
            attach: { previewID, book in
                book.$preview.id = previewID
            },
            configure: { preview, book in
                preview.primaryInfo = book.title
                preview.secondaryInfo = book.author
                preview.$image.id = book.cover?.id
                preview.externalLinks = book.resourceURLs
            },
            fetch: { book, database in
                try await book.$preview.load(on: database)
                return book.preview
            }
        )
    }
}
