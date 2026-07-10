import SwiftUI
import SwiftData
import AppPersistence

private struct AlbumInfoLine: View {
    let album: AlbumRecord

    var body: some View {
        if let text {
            Text(text).foregroundStyle(.secondary)
        }
    }

    private var text: String? {
        let parts = [album.genre, album.releaseDate?.formatted(date: .abbreviated, time: .omitted)]
            .compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

struct AlbumDetailSection: View {

    let item: PreviewRecord

    @Query
    private var records: [AlbumRecord]

    @Upserter(.album)
    private var syncer

    init(item: PreviewRecord) {
        self.item = item
        let previewID = item.id
        _records = Query(filter: #Predicate<AlbumRecord> { $0.previewID == previewID })
    }

    var body: some View {
        let album = records.first
        let artist = album?.artist ?? item.secondaryInfo
        Group {
            Section {
                CatalogueItemHeader(
                    title: album?.title ?? item.primaryInfo,
                    artworkURL: album?.artworkURL ?? item.imageURL,
                    credit: artist.isEmpty ? nil : "by \(artist)",
                    info: { if let album { AlbumInfoLine(album: album) } },
                    resourceURLs: album?.resourceURLs ?? item.externalLinks
                )
            }
            if let sourceID = item.sourceID {
                TrackListSection(containerType: "album", containerSourceID: sourceID)
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
