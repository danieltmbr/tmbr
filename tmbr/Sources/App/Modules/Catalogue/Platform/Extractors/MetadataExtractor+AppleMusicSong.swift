import Foundation

extension MetadataExtractor where M == SongMetadata {

    static let appleMusicSong = MetadataExtractor { url, fetcher in
        let song = try await fetcher(url)
        guard song.type == "music.song" else {
            throw MetadataExtractionError.invalidType(expected: "music.song", actual: song.type)
        }

        var albumURLComponents = song.tags["music:album"].flatMap(URLComponents.init)
        albumURLComponents?.queryItems = nil
        async let album = extract(
            key: "apple:title",
            from: albumURLComponents?.string,
            of: "music.album",
            with: fetcher
        )

        async let artist = extract(
            key: "apple:title",
            from: song.tags["music:musician"],
            of: "music.musician",
            with: fetcher
        )

        // Transform og:image URL to get square artwork
        // Original: .../1200x630bf-60.jpg -> Changed to: .../1000x1000.jpg
        let artwork = song.tags["og:image"].flatMap { urlString -> String? in
            guard var url = URL(string: urlString) else { return nil }
            url.deleteLastPathComponent()
            url.appendPathComponent("1000x1000.jpg")
            return url.absoluteString
        }

        return SongMetadata(
            album: try? await album,
            artist: try? await artist,
            artwork: artwork,
            externalID: song.tags["apple:content_id"],
            releaseDate: song.tags["music:release_date"],
            title: song.tags["apple:title"]
        )
    }
}
