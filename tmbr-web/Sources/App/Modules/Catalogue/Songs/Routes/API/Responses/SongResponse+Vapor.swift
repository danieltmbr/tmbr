import TmbrCore
import Vapor

extension SongResponse: @retroactive Content {}
extension SongResponse: @retroactive AsyncResponseEncodable {}
