import Foundation
import Vapor

public struct ErrorViewModel: Encodable, Sendable {
    
    private let title: String
    
    private let message: String
    
    private let suggestedFixes: [String]
    
    public init(
        title: String,
        message: String,
        suggestedFixes: [String] = [],
        markdownFormatter formatter: MarkdownFormatter = .html
    ) {
        self.title = title
        self.message = formatter.format(message)
        self.suggestedFixes = suggestedFixes
    }
    
    @Sendable
    public init(abort: AbortError) {
        self.init(
            title: abort.status.reasonPhrase,
            message: abort.reason,
            suggestedFixes: []
        )
    }
}

extension Template where Model == ErrorViewModel {
    
    static let error = Template(name: "Error/error")
}
