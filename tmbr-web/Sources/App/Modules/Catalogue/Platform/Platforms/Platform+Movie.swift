extension Platform where M == MovieMetadata {

    static var movie: Platform<MovieMetadata> {
        Platform(platforms: [
            Platform(name: "IMDb", checker: .imdb, extractor: .imdb),
            Platform(name: "Rotten Tomatoes", checker: .rottenTomatoes),
            Platform(name: "YouTube", checker: .youtube)
        ])
    }
}
