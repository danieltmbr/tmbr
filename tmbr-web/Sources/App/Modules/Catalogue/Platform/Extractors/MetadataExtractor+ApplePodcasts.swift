import Foundation

extension MetadataExtractor where M == PodcastMetadata {

    static let applePodcasts = MetadataExtractor { url, fetcher in
        let episode = try await fetcher(url)

        // Apple Podcasts sets og:type = "website" for all pages, so we validate
        // via JSON-LD @type to confirm this is an episode (not a show page).
        guard (episode.json["@type"] as? String) == "PodcastEpisode" else {
            throw MetadataExtractionError.invalidType(
                expected: "PodcastEpisode",
                actual: episode.json["@type"] as? String
            )
        }

        // Show title is in JSON-LD partOfSeries.name — no secondary fetch needed.
        let showTitle = (episode.json["partOfSeries"] as? [String: Any])?["name"] as? String

        // Episode and season numbers from JSON-LD.
        let episodeNumber = (episode.json["episodeNumber"] as? Int)
            ?? (episode.json["episodeNumber"] as? String).flatMap(Int.init)
        let seasonNumber = (episode.json["partOfSeason"] as? [String: Any])
            .flatMap { $0["seasonNumber"] as? Int }

        return PodcastMetadata(
            episodeTitle: episode.tags["apple:title"] ?? episode.tags["og:title"],
            showTitle: showTitle,
            artwork: episode.tags["og:image"],
            releaseDate: episode.json["datePublished"] as? String,
            episodeNumber: episodeNumber,
            seasonNumber: seasonNumber,
            externalID: episode.tags["apple:content_id"]
        )
    }
}
