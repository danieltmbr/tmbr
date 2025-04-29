import Foundation
import Vapor
import Leaf
import Markdown

struct PostViewModel: Content {

    let author: String
    
    let content: String

    let id: Int?
    
    let publishDate: String
    
    let title: String
    
    init(post: Post, markdownFormatter formatter: MarkdownFormatter = .html) {
        self.author = NameFormatter.author.format(
            givenName: post.$author.value?.firstName,
            familyName: post.$author.value?.lastName
        )
        self.content = formatter.format(post.content)
        self.id = post.id
        self.publishDate = post.createdAt.formatted(.publishDate)
        self.title = post.title
    }
}
