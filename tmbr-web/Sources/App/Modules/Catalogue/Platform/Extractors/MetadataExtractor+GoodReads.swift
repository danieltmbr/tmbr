import Foundation

extension MetadataExtractor where M == BookMetadata {

    static let goodreads = MetadataExtractor { url, fetcher in
        let book = try await fetcher(url)
        guard book.type == "books.book" else {
            throw MetadataExtractionError.invalidType(expected: "books.book", actual: book.type)
        }

        let authors = book.json["author"] as? [[String: Any]]
        let author = authors?.first?["name"] as? String

        return BookMetadata(
            author: author,
            cover: book.tags["og:image"],
            externalID: book.tags["books:isbn"] ?? book.json["isbn"] as? String,
            releaseDate: book.tags["books:release_date"] ?? book.json["datePublished"] as? String,
            title: book.tags["og:title"] ?? book.json["name"] as? String
        )
    }
}
