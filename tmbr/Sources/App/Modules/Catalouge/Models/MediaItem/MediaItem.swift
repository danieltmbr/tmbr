import Foundation
import Fluent

protocol MediaItem: Model {
    
    init(mediaID: Int)
    
    func resource(for platform: MediaPlatform<Self>) -> MediaResource<Self>?
    
    func upsert(resource: MediaResource<Self>, on database: any Database) async throws
    
    func upsert(resources: [MediaResource<Self>], on database: any Database) async throws
}

extension MediaItem {
    
    init(mediaID: Int, configure: ((Self) throws -> Void)) rethrows {
        self.init(mediaID: mediaID)
        try configure(self)
    }
    
    subscript(dynamicMember platform: MediaPlatform<Self>) -> MediaResource<Self>? {
        resource(for: platform)
    }
}
