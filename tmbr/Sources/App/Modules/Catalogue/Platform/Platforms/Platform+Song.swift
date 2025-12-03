extension Platform<Song> {
    
    static let all = Platform(platforms: [
        .appleMusic,
        .spotify,
        .youtube
    ])
    
    static let appleMusic = Platform(displayName: "Apple Music", parser: .appleMusic)

    static let spotify = Platform(displayName: "Spotify", parser: .spotify)
    
    static let youtube = Platform(displayName: "YouTube", parser: .youtube)
}
