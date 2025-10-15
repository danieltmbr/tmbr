import Foundation

extension MediaPayload {
    struct Podcast: Decodable, Sendable {
        
        /// Apple's Podcast app
        ///
        private let podcast: Resource?

        private let spotify: Resource?
        
        var resources: [MediaResource<App.Podcast>] {
            [
                podcast?.resource(platform: .podcast),
                spotify?.resource(platform: .spotify),
            ].compactMap(\.self)
        }
    }
}
