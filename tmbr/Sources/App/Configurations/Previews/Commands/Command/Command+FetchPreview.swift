import Foundation
import Vapor
import Core
import Logging
import Fluent

struct FetchPreviewParameters: Sendable {
    
    fileprivate let id: Int
    
    fileprivate let type: String
    
    init(id: Int, type: String) {
        self.id = id
        self.type = type
    }
}

extension CommandFactory where Input == FetchPreviewParameters, Output == Preview? {
    
    static var fetchPreview: Self {
        CommandFactory { request in
            PlainCommand { params in
                try await request.previews(for: params.type, id: params.id)
            }
            .logged(logger: request.logger)
        }
    }
}
