import TmbrCore
import Vapor

extension AlbumResponse: @retroactive Content {}
extension AlbumResponse: @retroactive AsyncResponseEncodable {}
