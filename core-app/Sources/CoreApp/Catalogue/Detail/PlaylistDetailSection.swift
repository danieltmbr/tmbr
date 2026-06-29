import SwiftUI
import SwiftData

struct PlaylistDetailSection: View {

    let previewID: UUID

    @Query private var records: [PlaylistRecord]

    @Upserter(\.playlist) private var syncer

    init(previewID: UUID) {
        self.previewID = previewID
        _records = Query(filter: #Predicate<PlaylistRecord> { $0.previewID == previewID })
    }

    var body: some View {
        if let playlist = records.first {
            Section {
                CatalogueItemHeader(
                    title: playlist.title,
                    artworkURL: playlist.artworkURL,
                    info: playlist.playlistDescription,
                    resourceURLs: playlist.resourceURLs
                )
            }
            .catalogueItemRefresh(id: previewID) { [sourceID = playlist.sourceID] in
                if let sourceID { try await syncer(sourceID) }
            }
            if let sourceID = playlist.sourceID {
                TrackListSection(containerType: "playlist", containerSourceID: sourceID)
            }
        }
    }
}
