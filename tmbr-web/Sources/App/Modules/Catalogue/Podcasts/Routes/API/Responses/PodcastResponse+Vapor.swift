import CoreTmbr
import Vapor

extension PodcastResponse: @retroactive Content {}
extension PodcastResponse: @retroactive AsyncResponseEncodable {}
