extension Platform<Podcast> {
    
    static let all = Platform(platforms: [
        .spotify,
        .applePodcasts
    ])
    
    static let spotify = Platform(displayName: "Spotify", parser: .spotify)

    static let applePodcasts = Platform(displayName: "Podcasts", parser: .applePodcasts)
}
