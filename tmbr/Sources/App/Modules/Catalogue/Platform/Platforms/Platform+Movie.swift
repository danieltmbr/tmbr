extension Platform<Movie> {
    
    static let all = Platform(platforms: [
        .imdb,
        .rottenTomatoes,
        .youtube
    ])
    
    static let imdb = Platform(displayName: "IMDb", parser: .imdb)

    static let rottenTomatoes = Platform(displayName: "Rotten Tomatoes", parser: .rottenTomatoes)
    
    static let youtube = Platform(displayName: "YouTube", parser: .youtube)
}
