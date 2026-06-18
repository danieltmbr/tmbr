import CoreTmbr
import Vapor

extension NoteResponse: @retroactive Content {}
extension NoteResponse: @retroactive AsyncResponseEncodable {}
