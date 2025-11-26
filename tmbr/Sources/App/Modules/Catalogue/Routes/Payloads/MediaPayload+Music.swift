import Foundation

typealias Entity = Music.Entity

extension MediaPayload {
    
    struct Music: Decodable, Sendable {
        
        let entity: Entity
        
        private let appleMusic: Resource?
        
        private let spotify: Resource?
        
        private let genius: Resource?
        
        var resources: [MediaResource<App.Music>] {
            [
                appleMusic?.resource(platform: .appleMusic),
                spotify?.resource(platform: .spotify),
                genius?.resource(platform: .genius)
            ].compactMap(\.self)
        }
    }
}
