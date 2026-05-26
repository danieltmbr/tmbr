import Foundation

struct RSSViewModel: Encodable {
    
    struct Post: Encodable {
        private let title: String
        
        private let url: String
        
        private let publishDate: String
        
        init(title: String, url: String, publishDate: String) {
            self.title = title
            self.url = url
            self.publishDate = publishDate
        }
    }
    
    private let title: String
    
    private let url: String
    
    private let description: String

    private let posts: [Post]
    
    init(
        title: String,
        url: String,
        description: String,
        posts: [Post]
    ) {
        self.title = title
        self.url = url
        self.description = description
        self.posts = posts
    }
}
