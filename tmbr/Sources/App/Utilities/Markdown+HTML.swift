import Foundation
@preconcurrency import Markdown

struct MarkdownFormatter: Sendable {
    typealias Formatter = @Sendable (String) -> String
    
    private let formatter: Formatter
    
    init(formatter: @escaping Formatter) {
        self.formatter = formatter
    }
    
    func format(_ markdown: String) -> String {
        formatter(markdown)
    }
    
    static let html = MarkdownFormatter { markdown in
        var walker = HTMLFormatter()
        walker.visit(Document(parsing: markdown))
        return walker.result
    }
}
