import Foundation
import CoreWeb
import CoreTmbr

extension Commands {
    var previews: Commands.Previews.Type { Commands.Previews.self }
}

extension Commands {
    struct Previews: CommandCollection, Sendable {

        let create: CommandFactory<CreatePreviewItemInput, Preview>

        let deleteContainerEntries: CommandFactory<DeleteContainerEntriesInput, Void>

        let fetch: CommandFactory<FetchParameters<PreviewID>, Preview>

        let findSongPreviewsByURL: CommandFactory<FindSongPreviewsByURLInput, [String: Preview]>

        let fetchContainerEntry: CommandFactory<ContainerEntryInput, ContainerEntry>

        let importTracks: CommandFactory<ImportAlbumTracksInput, Void>

        let list: CommandFactory<PreviewQueryInput, [Preview]>

        let listContainerEntries: CommandFactory<ContainerEntriesInput, [ContainerEntry]>

        let listContainerPreviews: CommandFactory<ContainerEntriesInput, [Preview]>

        let update: CommandFactory<UpdatePreviewItemInput, Preview>

        init(
            create: CommandFactory<CreatePreviewItemInput, Preview> = .createPreviewItem,
            deleteContainerEntries: CommandFactory<DeleteContainerEntriesInput, Void> = .deleteContainerEntries,
            fetch: CommandFactory<FetchParameters<PreviewID>, Preview> = .fetchPreview,
            findSongPreviewsByURL: CommandFactory<FindSongPreviewsByURLInput, [String: Preview]> = .findSongPreviewsByURL,
            fetchContainerEntry: CommandFactory<ContainerEntryInput, ContainerEntry> = .fetchContainerEntry,
            importTracks: CommandFactory<ImportAlbumTracksInput, Void> = .importAlbumTracks,
            list: CommandFactory<PreviewQueryInput, [Preview]> = .listPreviews,
            listContainerEntries: CommandFactory<ContainerEntriesInput, [ContainerEntry]> = .listContainerEntries,
            listContainerPreviews: CommandFactory<ContainerEntriesInput, [Preview]> = .listContainerPreviews,
            update: CommandFactory<UpdatePreviewItemInput, Preview> = .updatePreviewItem
        ) {
            self.create = create
            self.deleteContainerEntries = deleteContainerEntries
            self.fetch = fetch
            self.findSongPreviewsByURL = findSongPreviewsByURL
            self.fetchContainerEntry = fetchContainerEntry
            self.importTracks = importTracks
            self.list = list
            self.listContainerEntries = listContainerEntries
            self.listContainerPreviews = listContainerPreviews
            self.update = update
        }
    }
}
