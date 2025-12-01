import Foundation
import AuthKit

struct NotePayload: Decodable {
    var body: String
    
    var access: Access

    var attachmentID: UUID
}
