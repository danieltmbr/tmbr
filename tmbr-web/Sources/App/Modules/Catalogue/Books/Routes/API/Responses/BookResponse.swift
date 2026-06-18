import Foundation
import CoreTmbr
import CoreAuth
import CoreWeb

extension BookResponse {

    init(
        book: Book,
        baseURL: String,
        notes: [Note],
        platform: Platform<BookMetadata> = .book
    ) {
        self.init(
            id: book.id!,
            access: book.access,
            author: book.author,
            cover: book.cover.map { ImageResponse(image: $0, baseURL: baseURL) },
            genre: book.genre,
            notes: notes.map { NoteResponse(note: $0, baseURL: baseURL) },
            owner: UserResponse(user: book.owner),
            preview: PreviewResponse(preview: book.preview, baseURL: baseURL),
            post: book.post.map { PostResponse(post: $0, baseURL: baseURL) },
            releaseDate: book.releaseDate,
            resources: book.resourceURLs.compactMap(platform.hyperlink),
            title: book.title
        )
    }
}
