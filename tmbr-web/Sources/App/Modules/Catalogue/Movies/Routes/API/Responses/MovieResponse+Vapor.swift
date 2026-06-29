import TmbrCore
import Vapor

extension MovieResponse: @retroactive Content {}
extension MovieResponse: @retroactive AsyncResponseEncodable {}
