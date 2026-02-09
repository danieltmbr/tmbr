extension Platform where M == Void {

    static var song: Platform<Void> {
        Platform(platforms: [
            Platform(name: "Apple Music", checker: .appleMusic),
            Platform(name: "Spotify", checker: .spotify),
            Platform(name: "YouTube", checker: .youtube)
        ])
    }
}
