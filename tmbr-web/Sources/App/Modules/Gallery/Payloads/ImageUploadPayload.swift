import Vapor

struct ImageUploadPayload: Content {
    
    let image: File
    
    let alt: String?
}
