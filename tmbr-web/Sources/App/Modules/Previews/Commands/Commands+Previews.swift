import Foundation
import Core
import TmbrCore

extension Commands {
    var previews: Commands.Previews.Type { Commands.Previews.self }
}

extension Commands {
    struct Previews: CommandCollection, Sendable {

        let create: CommandFactory<CreatePreviewItemInput, Preview>

        let deleteContainerEntries: CommandFactory<DeleteContainerEntriesInput, Void>

        let fetch: CommandFactory<FetchParameters<PreviewID>, Preview>

        let fetchContainerEntry: CommandFactory<ContainerEntryInput, ContainerEntry>

        let importTracks: CommandFactory<ImportAlbumTracksInput, Void>

        let list: CommandFactory<PreviewQueryInput, [Preview]>

        let listContainerEntries: CommandFactory<ContainerEntriesInput, [ContainerEntry]>

        let syncContainerEntries: CommandFactory<SyncContainerEntriesInput, Void>

        let update: CommandFactory<UpdatePreviewItemInput, Preview>

        init(
            create: CommandFactory<CreatePreviewItemInput, Preview> = .createPreviewItem,
            deleteContainerEntries: CommandFactory<DeleteContainerEntriesInput, Void> = .deleteContainerEntries,
            fetch: CommandFactory<FetchParameters<PreviewID>, Preview> = .fetchPreview,
            fetchContainerEntry: CommandFactory<ContainerEntryInput, ContainerEntry> = .fetchContainerEntry,
            importTracks: CommandFactory<ImportAlbumTracksInput, Void> = .importAlbumTracks,
            list: CommandFactory<PreviewQueryInput, [Preview]> = .listPreviews,
            listContainerEntries: CommandFactory<ContainerEntriesInput, [ContainerEntry]> = .listContainerEntries,
            syncContainerEntries: CommandFactory<SyncContainerEntriesInput, Void> = .syncContainerEntries,
            update: CommandFactory<UpdatePreviewItemInput, Preview> = .updatePreviewItem
        ) {
            self.create = create
            self.deleteContainerEntries = deleteContainerEntries
            self.fetch = fetch
            self.fetchContainerEntry = fetchContainerEntry
            self.importTracks = importTracks
            self.list = list
            self.listContainerEntries = listContainerEntries
            self.syncContainerEntries = syncContainerEntries
            self.update = update
        }
    }
}
