import Foundation
import Core

extension Commands {
    var previews: Commands.Previews.Type { Commands.Previews.self }
}

extension Commands {
    struct Previews: CommandCollection, Sendable {
        
        let fetch: CommandFactory<FetchPreviewParameters, Preview?>
        
        init(
            fetch: CommandFactory<FetchPreviewParameters, Preview?> = .fetchPreview,
        ) {
            self.fetch = fetch
        }
    }
}
