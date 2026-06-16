import CoreTmbr
import Vapor

extension AlbumResponse: @retroactive Content {}
extension AlbumResponse: @retroactive AsyncResponseEncodable {}
