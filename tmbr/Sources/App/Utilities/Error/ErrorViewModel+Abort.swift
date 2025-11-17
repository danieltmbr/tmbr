import Foundation
import CoreWeb
import Core
import Vapor

extension ErrorViewModel {
    
    @Sendable
    init(abort: AbortError & DebuggableError) {
        self.init(
            title: abort.status.reasonPhrase,
            message: MarkdownFormatter.html.format(abort.reason),
            suggestedFixes: abort.suggestedFixes
        )
    }
}
