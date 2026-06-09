import Foundation

extension MetadataExtractor where M == AlbumMetadata {

    static let appleMusicAlbum = MetadataExtractor { url, fetcher in
        let metadata = try await fetcher(url)
        guard metadata.type == "music.album" else {
            throw MetadataExtractionError.invalidType(expected: "music.album", actual: metadata.type)
        }

        let artwork = metadata.tags["og:image"].flatMap { urlString -> String? in
            guard var url = URL(string: urlString) else { return nil }
            url.deleteLastPathComponent()
            url.appendPathComponent("1000x1000.jpg")
            return url.absoluteString
        }

        let namedBlock = metadata.json["schema:music-album"] as? [String: Any]
        let atTypeFallback = metadata.json["@type"] as? String == "MusicAlbum" ? metadata.json : nil
        let albumJSON: [String: Any]? = namedBlock ?? atTypeFallback

        let artist = (albumJSON?["byArtist"] as? [[String: Any]])?.first?["name"] as? String
            ?? (albumJSON?["byArtist"] as? [String: Any])?["name"] as? String

        let genre = (albumJSON?["genre"] as? [String])?.first
            ?? albumJSON?["genre"] as? String

        let tracks: [TrackMetadata]? = (albumJSON?["track"] as? [[String: Any]])?.compactMap { track in
            guard let name = track["name"] as? String else { return nil }
            return TrackMetadata(name: name, url: track["url"] as? String)
        }

        return AlbumMetadata(
            artist: artist,
            artwork: artwork,
            externalID: metadata.tags["apple:content_id"],
            genre: genre,
            releaseDate: albumJSON?["datePublished"] as? String ?? metadata.tags["music:release_date"],
            title: metadata.tags["apple:title"],
            tracks: tracks?.isEmpty == false ? tracks : nil
        )
    }
}
