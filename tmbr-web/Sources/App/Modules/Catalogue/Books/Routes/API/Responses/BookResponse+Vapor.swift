import CoreTmbr
import Vapor

extension BookResponse: @retroactive Content {}
extension BookResponse: @retroactive AsyncResponseEncodable {}
