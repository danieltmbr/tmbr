import Foundation
@preconcurrency import Markdown

public struct MarkdownFormatter: Sendable {
    typealias Formatter = @Sendable (String) -> String
    
    private let formatter: Formatter
    
    init(formatter: @escaping Formatter) {
        self.formatter = formatter
    }
    
    public func format(_ markdown: String) -> String {
        formatter(markdown)
    }
    
    public static let html = MarkdownFormatter { markdown in
        var walker = HTMLFormatter()
        walker.visit(Document(parsing: markdown))
        return walker.result
    }
}
