import Foundation

extension MetadataExtractor where M == PlaylistMetadata {

    static let appleMusicPlaylist = MetadataExtractor { url, fetcher in
        let metadata = try await fetcher(url)
        guard metadata.type == "music.playlist" else {
            throw MetadataExtractionError.invalidType(expected: "music.playlist", actual: metadata.type)
        }

        let original = metadata.tags["og:image"]
        let resized = original.flatMap { urlString -> String? in
            guard var url = URL(string: urlString) else { return nil }
            url.deleteLastPathComponent()
            url.appendPathComponent("1000x1000.jpg")
            return url.absoluteString
        }
        let artwork: MetadataArtwork? = original != nil ? MetadataArtwork(resized: resized, original: original) : nil

        // Apple Music playlists embed JSON-LD in a block tagged id="schema:music-playlist".
        // User-created playlists omit this block; songs appear in repeated music:song meta tags instead.
        let playlistJSON = metadata.json["schema:music-playlist"] as? [String: Any]

        var tracks: [TrackMetadata]? = (playlistJSON?["track"] as? [[String: Any]])?.compactMap { track in
            guard let name = track["name"] as? String else { return nil }
            return TrackMetadata(name: name, url: track["url"] as? String)
        }

        if tracks == nil || tracks?.isEmpty == true {
            let songURLs = metadata.multiTags["music:song"] ?? []
            if !songURLs.isEmpty {
                tracks = songURLs.compactMap { urlString -> TrackMetadata? in
                    guard let songURL = URL(string: urlString) else { return nil }
                    let components = songURL.pathComponents
                    // URL path: ["", "locale", "song", "slug-name", "id"]
                    let slug = components.count >= 2 ? components[components.count - 2] : nil
                    let name = slug
                        .flatMap { $0.removingPercentEncoding ?? $0 }
                        .map { $0.replacingOccurrences(of: "-", with: " ").capitalized }
                        ?? urlString
                    return TrackMetadata(name: name, url: urlString)
                }
            }
        }

        let createdAt = playlistJSON?["dateCreated"] as? String
            ?? playlistJSON?["datePublished"] as? String

        return PlaylistMetadata(
            artwork: artwork,
            createdAt: createdAt,
            description: metadata.tags["og:description"],
            title: metadata.tags["og:title"] ?? metadata.tags["apple:title"],
            tracks: tracks?.isEmpty == false ? tracks : nil
        )
    }
}
