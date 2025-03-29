import Fluent
import Vapor

struct PostDTO: Content {
    let id: UUID?
    
    let title: String
    
    let content: String
    
    let createdAt: Date
    
    func toModel() -> Post {
        Post(
            id: id,
            title: title,
            content: content,
            createdAt: createdAt
        )
    }
}
