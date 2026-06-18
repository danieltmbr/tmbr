import CoreTmbr
import Vapor

extension SongResponse: @retroactive Content {}
extension SongResponse: @retroactive AsyncResponseEncodable {}
