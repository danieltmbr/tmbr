import Foundation

struct RSSViewModel: Encodable {
    
    struct Post: Encodable {
        let title: String
        
        let url: String
        
        let publishDate: String
    }
    
    let title: String
    
    let url: String
    
    let description: String

    let posts: [Post]
}
