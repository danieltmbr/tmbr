extension Platform where M == PodcastMetadata {

    static var podcast: Platform<PodcastMetadata> {
        Platform(platforms: [
            Platform(name: "Spotify", checker: .spotify),
            Platform(name: "Podcasts", checker: .applePodcasts, extractor: .applePodcasts)
        ])
    }
}
