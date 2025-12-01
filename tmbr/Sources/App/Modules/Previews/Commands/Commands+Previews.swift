import Foundation
import Core

extension Commands {
    var previews: Commands.Previews.Type { Commands.Previews.self }
}

extension Commands {
    struct Previews: CommandCollection, Sendable {
        
        let fetch: CommandFactory<FetchParameters<PreviewID>, Preview>
        
        let list: CommandFactory<PreviewQueryInput, [Preview]>
                
        init(
            fetch: CommandFactory<FetchParameters<PreviewID>, Preview> = .fetchPreview,
            list: CommandFactory<PreviewQueryInput, [Preview]> = .listPreviews
        ) {
            self.fetch = fetch
            self.list = list
        }
    }
}
