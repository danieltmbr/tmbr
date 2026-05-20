import Foundation

extension MetadataExtractor where M == PodcastMetadata {

    static let applePodcasts = MetadataExtractor { url, fetcher in
        let episode = try await fetcher(url)
        guard episode.type == "music.episode" else {
            throw MetadataExtractionError.invalidType(expected: "music.episode", actual: episode.type)
        }

        // Try fetching the show page to extract its title — same pattern as album fetch in appleMusicSong.
        // Strip the ?i= episode param so we hit the show URL.
        var showComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        showComponents?.queryItems = nil
        let showTitle = try? await MetadataExtractor.extract(
            key: "og:title",
            from: showComponents?.string,
            of: "music.album",
            with: fetcher
        )

        // Episode/season numbers from JSON-LD if the page exposes them.
        let episodeNumber = (episode.json["episodeNumber"] as? Int)
            ?? (episode.json["episodeNumber"] as? String).flatMap(Int.init)
        let seasonNumber = (episode.json["partOfSeason"] as? [String: Any])
            .flatMap { $0["seasonNumber"] as? Int }

        // Release date prefers the structured tag; falls back to JSON-LD datePublished.
        let releaseDate = episode.tags["music:release_date"]
            ?? episode.json["datePublished"] as? String

        // ExternalID: episode ID from the URL query parameter `i`.
        let externalID = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "i" })?
            .value

        return PodcastMetadata(
            episodeTitle: episode.tags["og:title"] ?? episode.tags["apple:title"],
            showTitle: showTitle,
            artwork: episode.tags["og:image"],
            releaseDate: releaseDate,
            episodeNumber: episodeNumber,
            seasonNumber: seasonNumber,
            externalID: externalID
        )
    }
}
