extension Platform where M == Void {

    static var podcast: Platform<Void> {
        Platform(platforms: [
            Platform(name: "Spotify", checker: .spotify),
            Platform(name: "Podcasts", checker: .applePodcasts)
        ])
    }
}
