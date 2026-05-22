import Foundation

extension MetadataExtractor where M == AlbumMetadata {

    static let appleMusicAlbum = MetadataExtractor { url, fetcher in
        let album = try await fetcher(url)
        guard album.type == "music.album" else {
            throw MetadataExtractionError.invalidType(expected: "music.album", actual: album.type)
        }

        async let artist = extract(
            key: "apple:title",
            from: album.tags["music:musician"],
            of: "music.musician",
            with: fetcher
        )

        // Transform og:image URL to get square artwork
        // Original: .../1200x630bf-60.jpg -> Changed to: .../1000x1000.jpg
        let artwork = album.tags["og:image"].flatMap { urlString -> String? in
            guard var url = URL(string: urlString) else { return nil }
            url.deleteLastPathComponent()
            url.appendPathComponent("1000x1000.jpg")
            return url.absoluteString
        }

        return AlbumMetadata(
            artist: try? await artist,
            artwork: artwork,
            externalID: album.tags["apple:content_id"],
            releaseDate: album.tags["music:release_date"],
            title: album.tags["apple:title"]
        )
    }
}
