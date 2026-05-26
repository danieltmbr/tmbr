import Foundation

extension MetadataExtractor where M == MovieMetadata {

    static let imdb = MetadataExtractor { url, fetcher in
        let movie = try await fetcher(url)
        guard movie.type == "video.movie" else {
            throw MetadataExtractionError.invalidType(expected: "video.movie", actual: movie.type)
        }

        let directors = movie.json["director"] as? [[String: Any]]
        let director = directors?.first?["name"] as? String

        let title = movie.json["name"] as? String ?? movie.tags["og:title"]
        let releaseDate = movie.json["datePublished"] as? String
        let externalID = url.pathComponents.first(where: { $0.hasPrefix("tt") && $0.count > 2 })

        return MovieMetadata(
            title: title,
            director: director,
            cover: movie.tags["og:image"],
            releaseDate: releaseDate,
            externalID: externalID
        )
    }
}
