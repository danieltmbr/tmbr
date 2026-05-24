import Foundation
import Core
import TmbrCore

extension Commands {
    var previews: Commands.Previews.Type { Commands.Previews.self }
}

extension Commands {
    struct Previews: CommandCollection, Sendable {

        let fetch: CommandFactory<FetchParameters<PreviewID>, Preview>

        let fetchContainerEntry: CommandFactory<ContainerEntryInput, ContainerEntry>

        let importTracks: CommandFactory<ImportAlbumTracksInput, Void>

        let list: CommandFactory<PreviewQueryInput, [Preview]>

        let listContainerEntries: CommandFactory<ContainerEntriesInput, [ContainerEntry]>

        init(
            fetch: CommandFactory<FetchParameters<PreviewID>, Preview> = .fetchPreview,
            fetchContainerEntry: CommandFactory<ContainerEntryInput, ContainerEntry> = .fetchContainerEntry,
            importTracks: CommandFactory<ImportAlbumTracksInput, Void> = .importAlbumTracks,
            list: CommandFactory<PreviewQueryInput, [Preview]> = .listPreviews,
            listContainerEntries: CommandFactory<ContainerEntriesInput, [ContainerEntry]> = .listContainerEntries
        ) {
            self.fetch = fetch
            self.fetchContainerEntry = fetchContainerEntry
            self.importTracks = importTracks
            self.list = list
            self.listContainerEntries = listContainerEntries
        }
    }
}
