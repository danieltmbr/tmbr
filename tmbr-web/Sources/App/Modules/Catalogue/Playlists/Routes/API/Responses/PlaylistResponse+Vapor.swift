import CoreTmbr
import Vapor

extension PlaylistResponse: @retroactive Content {}
extension PlaylistResponse: @retroactive AsyncResponseEncodable {}
