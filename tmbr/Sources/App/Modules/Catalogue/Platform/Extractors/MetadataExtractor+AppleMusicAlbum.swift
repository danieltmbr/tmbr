import Foundation

extension MetadataExtractor where M == AlbumMetadata {

    static let appleMusicAlbum = MetadataExtractor { url, fetcher in
        let metadata = try await fetcher(url)
        guard metadata.type == "music.album" else {
            throw MetadataExtractionError.invalidType(expected: "music.album", actual: metadata.type)
        }

        // Transform og:image URL to get square artwork
        // Original: .../1200x630bf-60.jpg -> Changed to: .../1000x1000.jpg
        let artwork = metadata.tags["og:image"].flatMap { urlString -> String? in
            guard var url = URL(string: urlString) else { return nil }
            url.deleteLastPathComponent()
            url.appendPathComponent("1000x1000.jpg")
            return url.absoluteString
        }

        // Apple Music album JSON-LD is in the script tagged id="schema:music-album"
        let albumJSON = metadata.json["schema:music-album"] as? [String: Any]

        // Use byArtist from JSON-LD as primary source — avoids an extra network request
        let artistFromJSON = (albumJSON?["byArtist"] as? [[String: Any]])?.first?["name"] as? String
            ?? (albumJSON?["byArtist"] as? [String: Any])?["name"] as? String
        let artist = artistFromJSON ?? metadata.tags["apple:title"].flatMap { _ in
            // Fall back to fetching the musician page only if JSON-LD has no artist
            nil as String?
        }

        let tracks: [TrackMetadata]? = (albumJSON?["tracks"] as? [[String: Any]])?.compactMap { track in
            guard let name = track["name"] as? String else { return nil }
            return TrackMetadata(name: name, url: track["url"] as? String)
        }

        return AlbumMetadata(
            artist: artist,
            artwork: artwork,
            externalID: metadata.tags["apple:content_id"],
            releaseDate: albumJSON?["datePublished"] as? String ?? metadata.tags["music:release_date"],
            title: metadata.tags["apple:title"],
            tracks: tracks?.isEmpty == false ? tracks : nil
        )
    }
}
