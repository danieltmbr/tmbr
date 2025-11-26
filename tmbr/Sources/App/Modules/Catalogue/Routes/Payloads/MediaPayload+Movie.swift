
extension MediaPayload {
    struct Movie: Decodable, Sendable {
        
        private let imdb: Resource?
        
        let imdbScore: Double?
        
        private let rottenTomatoes: Resource?
        
        let rottenTomatoesScore: Double?
        
        var resources: [MediaResource<App.Movie>] {
            [
                imdb?.resource(platform: .imdb),
                rottenTomatoes?.resource(platform: .rottenTomatoes),
            ].compactMap(\.self)
        }
    }
}
