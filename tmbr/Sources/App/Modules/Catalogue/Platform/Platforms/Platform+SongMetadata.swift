extension Platform where M == SongMetadata {

    static let all = Platform(platforms: [
        .appleMusic,
        .spotify,
        .youtube
    ])

    static let appleMusic = Platform(
        name: "Apple Music",
        checker: .appleMusic,
        extractor: .appleMusicSong
    )

    static let spotify = Platform(name: "Spotify", checker: .spotify)

    static let youtube = Platform(name: "YouTube", checker: .youtube)
}
