extension Platform where M == SongMetadata {

    static var song: Platform<SongMetadata> {
        Platform(platforms: [
            Platform(name: "Apple Music", checker: .appleMusic, extractor: .appleMusicSong),
            Platform(name: "Spotify", checker: .spotify, extractor: .spotifySong),
            Platform(name: "YouTube", checker: .youtube)
        ])
    }
}
