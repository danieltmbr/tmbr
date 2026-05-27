import TmbrCore
import Vapor

extension AuthResponse: @retroactive Content {}
extension AuthResponse: @retroactive AsyncResponseEncodable {}
