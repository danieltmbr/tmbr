extension Platform where M == PlaylistMetadata {

    static var playlist: Platform<PlaylistMetadata> {
        Platform(platforms: [
            Platform(name: "Apple Music", checker: .appleMusic),
            Platform(name: "Spotify", checker: .spotify),
            Platform(name: "YouTube", checker: .youtube)
        ])
    }
}
