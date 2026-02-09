import Foundation

extension MetadataExtractor where M == SongMetadata {

    static let spotifySong = MetadataExtractor { url, fetcher in
        let song = try await fetcher(url)
        guard song.type == "music.song" else {
            throw MetadataExtractionError.invalidType(expected: "music.song", actual: song.type)
        }

        let album = try? await extract(
            key: "og:title",
            from: song.data["music:album"],
            of: "music.album",
            with: fetcher
        )

        // Spotify URLs: https://open.spotify.com/track/<id>
        let components = url.pathComponents.filter { $0 != "/" }
        let songID = (components.count >= 2 && components.first == "track") ? components.last : nil
        
        return SongMetadata(
            album: album,
            artist: song.data["music:musician_description"],
            artwork: song.data["og:image"],
            externalID: songID,
            releaseDate: song.data["music:release_date"],
            title: song.data["og:title"]
        )
    }
}
