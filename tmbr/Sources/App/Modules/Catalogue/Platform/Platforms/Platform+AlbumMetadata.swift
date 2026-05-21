extension Platform where M == AlbumMetadata {

    static var album: Platform<AlbumMetadata> {
        Platform(platforms: [
            Platform(name: "Apple Music", checker: .appleMusic),
            Platform(name: "Spotify", checker: .spotify),
        ])
    }
}
