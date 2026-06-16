import CoreTmbr
import Vapor

extension DeletionRecord: @retroactive Content {}
extension DeletionRecord: @retroactive AsyncResponseEncodable {}
