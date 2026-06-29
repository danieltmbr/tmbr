import TmbrCore
import Vapor

extension DeletionRecord: @retroactive Content {}
extension DeletionRecord: @retroactive AsyncResponseEncodable {}
