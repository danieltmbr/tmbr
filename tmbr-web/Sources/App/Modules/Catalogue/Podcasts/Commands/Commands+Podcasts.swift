import Foundation
import Core
import TmbrCore

extension Commands {
    var podcasts: Commands.Podcasts.Type { Commands.Podcasts.self }
}

extension Commands {
    
    struct Podcasts: CommandCollection, Sendable {

        let create: CommandFactory<PodcastInput, Podcast>

        let delete: CommandFactory<PodcastID, Void>

        let edit: CommandFactory<EditPodcastInput, Podcast>

        let fetch: CommandFactory<FetchParameters<PodcastID>, Podcast>

        let list: CommandFactory<PageInput, [Podcast]>

        let lookup: CommandFactory<String, Podcast?>

        let metadata: CommandFactory<URL, PodcastMetadata>

        let search: CommandFactory<String?, PodcastSearchResult>

        init(
            create: CommandFactory<PodcastInput, Podcast> = .createPodcast,
            delete: CommandFactory<PodcastID, Void> = .delete(\.podcasts),
            edit: CommandFactory<EditPodcastInput, Podcast> = .editPodcast,
            fetch: CommandFactory<FetchParameters<PodcastID>, Podcast> = .fetchPodcast,
            list: CommandFactory<PageInput, [Podcast]> = .listPodcasts,
            lookup: CommandFactory<String, Podcast?> = .lookupPodcast,
            metadata: CommandFactory<URL, PodcastMetadata> = .fetchPodcastMetadata,
            search: CommandFactory<String?, PodcastSearchResult> = .searchPodcasts
        ) {
            self.create = create
            self.delete = delete
            self.edit = edit
            self.fetch = fetch
            self.list = list
            self.lookup = lookup
            self.metadata = metadata
            self.search = search
        }
    }
}
