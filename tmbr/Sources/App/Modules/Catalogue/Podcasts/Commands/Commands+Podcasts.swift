import Foundation
import Core

extension Commands {
    var podcasts: Commands.Podcasts.Type { Commands.Podcasts.self }
}

extension Commands {
    
    struct Podcasts: CommandCollection, Sendable {
        
        let create: CommandFactory<PodcastInput, Podcast>
        
        let delete: CommandFactory<PodcastID, Void>
        
        let edit: CommandFactory<EditPodcastInput, Podcast>
        
        let fetch: CommandFactory<FetchParameters<PodcastID>, Podcast>
        
        init(
            create: CommandFactory<PodcastInput, Podcast> = .createPodcast,
            delete: CommandFactory<PodcastID, Void> = .delete(\.podcasts),
            edit: CommandFactory<EditPodcastInput, Podcast> = .editPodcast,
            fetch: CommandFactory<FetchParameters<PodcastID>, Podcast> = .fetchPodcast
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
        }
    }
}
