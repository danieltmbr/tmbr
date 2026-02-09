import Foundation

extension MetadataExtractor where M == SongMetadata {

    static let appleMusicSong = MetadataExtractor { url, fetcher in
        let song = try await fetcher(url)
        guard song.type == "music.song" else {
            throw MetadataExtractionError.invalidType(expected: "music.song", actual: song.type)
        }

        async let album = extract(
            key: "apple:title",
            from: song.data["music:album"],
            of: "music.album",
            with: fetcher
        )

        async let artist = extract(
            key: "apple:title",
            from: song.data["music:musician"],
            of: "music.musician",
            with: fetcher
        )

        return SongMetadata(
            album: try? await album,
            artist: try? await artist,
            artwork: nil,
            externalID: song.data["apple:content_id"],
            releaseDate: song.data["music:release_date"],
            title: song.data["apple:title"]
        )
    }
}
