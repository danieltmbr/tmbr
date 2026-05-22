import Foundation

extension MetadataExtractor where M == PlaylistMetadata {

    static let appleMusicPlaylist = MetadataExtractor { url, fetcher in
        let metadata = try await fetcher(url)
        guard metadata.type == "music.playlist" else {
            throw MetadataExtractionError.invalidType(expected: "music.playlist", actual: metadata.type)
        }

        let artwork = metadata.tags["og:image"].flatMap { urlString -> String? in
            guard var url = URL(string: urlString) else { return nil }
            url.deleteLastPathComponent()
            url.appendPathComponent("1000x1000.jpg")
            return url.absoluteString
        }

        // Apple Music playlists embed JSON-LD in a block tagged id="schema:music-playlist"
        let playlistJSON = metadata.json["schema:music-playlist"] as? [String: Any]

        let tracks: [TrackMetadata]? = (playlistJSON?["tracks"] as? [[String: Any]])?.compactMap { track in
            guard let name = track["name"] as? String else { return nil }
            return TrackMetadata(name: name, url: track["url"] as? String)
        }

        return PlaylistMetadata(
            artwork: artwork,
            description: metadata.tags["og:description"],
            title: metadata.tags["og:title"] ?? metadata.tags["apple:title"],
            tracks: tracks?.isEmpty == false ? tracks : nil
        )
    }
}
