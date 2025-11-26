import Vapor
import Foundation

struct MediaResourcePayload: Decodable, Sendable {
    
    enum MappingError: Error {
        case unsupportedPlatform(String)
    }
    
    let externalID: String
    
    let platform: String
    
    let url: URL
    
    func resource<Item: MediaItem>(
        supportedPlatforms: Set<MediaPlatform<Item>>
    ) throws -> MediaResource<Item> {
        let platform = MediaPlatform<Item>(self.platform)
        guard supportedPlatforms.contains(platform) else {
            throw MappingError.unsupportedPlatform(self.platform)
        }
        return MediaResource(
            platform: platform,
            externalID: externalID,
            url: url
        )
    }
}
