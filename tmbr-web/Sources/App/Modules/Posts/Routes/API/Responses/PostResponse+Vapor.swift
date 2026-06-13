import TmbrCore
import Vapor

extension PostResponse: @retroactive Content {}
extension PostResponse: @retroactive AsyncResponseEncodable {}
