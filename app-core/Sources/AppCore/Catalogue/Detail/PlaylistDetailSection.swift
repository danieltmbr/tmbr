import SwiftUI
import SwiftData
import AppPersistence

private struct PlaylistInfoLine: View {
    let playlist: PlaylistRecord

    var body: some View {
        if let description = playlist.playlistDescription, !description.isEmpty {
            Text(description).foregroundStyle(.secondary)
        }
    }
}

struct PlaylistDetailSection: View {

    let item: PreviewRecord

    @Query private var records: [PlaylistRecord]

    @Upserter(.playlist) private var syncer

    init(item: PreviewRecord) {
        self.item = item
        let previewID = item.id
        _records = Query(filter: #Predicate<PlaylistRecord> { $0.previewID == previewID })
    }

    var body: some View {
        let playlist = records.first
        Group {
            Section {
                CatalogueItemHeader(
                    title: playlist?.title ?? item.primaryInfo,
                    artworkURL: playlist?.artworkURL ?? item.imageURL,
                    info: { if let playlist { PlaylistInfoLine(playlist: playlist) } },
                    resourceURLs: playlist?.resourceURLs ?? item.externalLinks
                )
            }
            if let sourceID = item.sourceID {
                TrackListSection(containerType: "playlist", containerSourceID: sourceID)
            }
        }
        .catalogueItemRefresh(id: item.id) { [sourceID = item.sourceID] in
            if let sourceID { try await syncer(sourceID) }
        }
        .task(id: item.id) {
            guard records.isEmpty, let sourceID = item.sourceID else { return }
            try? await syncer(sourceID)
        }
    }
}
