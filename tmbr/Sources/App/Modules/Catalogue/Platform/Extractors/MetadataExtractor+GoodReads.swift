import Foundation

extension MetadataExtractor where M == BookMetadata {

    static let goodreads = MetadataExtractor { url, fetcher in
        let book = try await fetcher(url)
        guard book.type == "books.book" else {
            throw MetadataExtractionError.invalidType(expected: "books.book", actual: book.type)
        }

        // Follow the author page URL to get the author's name via og:title
        let author = try? await extract(
            key: "og:title",
            from: book.data["books:author"],
            of: "books.author",
            with: fetcher
        )

        return BookMetadata(
            author: author,
            cover: book.data["og:image"],
            externalID: book.data["books:isbn"],
            releaseDate: book.data["books:release_date"],
            title: book.data["og:title"]
        )
    }
}
