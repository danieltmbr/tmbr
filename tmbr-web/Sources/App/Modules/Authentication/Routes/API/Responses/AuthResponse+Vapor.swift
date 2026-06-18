import CoreTmbr
import Vapor

extension AuthResponse: @retroactive Content {}
extension AuthResponse: @retroactive AsyncResponseEncodable {}
