import Foundation
import Vapor

public struct ErrorViewModel: Encodable, Sendable {
    
    private let title: String
    
    private let message: String
    
    private let suggestedFixes: [String]
    
    public init(
        title: String,
        message: String,
        suggestedFixes: [String] = []
    ) {
        self.title = title
        self.message = message
        self.suggestedFixes = suggestedFixes
    }
    
    @Sendable
    public init(abort: Abort) {
        self.init(
            title: abort.status.reasonPhrase,
            message: abort.reason,
            suggestedFixes: abort.suggestedFixes
        )
    }
}

extension Template where Model == ErrorViewModel {
    
    static let error = Template(name: "error")
}
