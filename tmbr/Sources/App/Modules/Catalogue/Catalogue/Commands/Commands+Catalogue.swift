import Foundation
import Core

extension Commands {
    var catalogue: Commands.Catalogue.Type { Commands.Catalogue.self }
}

extension Commands {
    
    struct Catalogue: CommandCollection, Sendable {
        
        let metadata: CommandFactory<URL, Metadata>
        
        init(
            metadata: CommandFactory<URL, Metadata> = .fetchMetadata
        ) {
            self.metadata = metadata
        }
    }
}
