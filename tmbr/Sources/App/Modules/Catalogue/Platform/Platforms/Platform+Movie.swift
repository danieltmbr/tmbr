extension Platform where M == Void {

    static var movie: Platform<Void> {
        Platform(platforms: [
            Platform(name: "IMDb", checker: .imdb),
            Platform(name: "Rotten Tomatoes", checker: .rottenTomatoes),
            Platform(name: "YouTube", checker: .youtube)
        ])
    }
}
