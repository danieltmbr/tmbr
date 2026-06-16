import CoreTmbr
import Vapor

extension PostResponse: @retroactive Content {}
extension PostResponse: @retroactive AsyncResponseEncodable {}
