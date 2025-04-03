import Foundation
import Vapor
import Leaf
@preconcurrency import Ink

struct PostViewModel: Content {

    let author: String
    
    let content: String

    let id: Int?
    
    let publishDate: String
    
    let title: String
    
    init(post: Post, parser: MarkdownParser = .post) {
        self.author = PersonNameComponents(
            givenName: post.$author.value?.firstName,
            familyName: post.$author.value?.lastName
        ).formatted(.name(style: .long))
        self.content = parser.html(from: post.content)
        self.id = post.id
        self.publishDate = post.createdAt.formatted(
            date: .complete,
            time: .omitted
        )
        self.title = post.title
    }
}

extension MarkdownParser {
    static let post = MarkdownParser(modifiers: [.quote])
}

extension Modifier {
    static let quote = Modifier(target: .blockquotes) { html, markdown in
        let content = markdown
            .replacingOccurrences(of: "> ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return "<blockquote><p>“\(content)”</p></blockquote>"
    }
}
