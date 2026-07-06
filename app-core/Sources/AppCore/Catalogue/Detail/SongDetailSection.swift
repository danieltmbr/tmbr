import SwiftUI
import SwiftData
import AppPersistence

private struct SongInfoLine: View {
    let song: SongRecord

    var body: some View {
        if let text {
            Text(text).foregroundStyle(.secondary)
        }
    }

    private var text: String? {
        let parts = [song.album, song.genre, song.releaseDate?.formatted(date: .abbreviated, time: .omitted)]
            .compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

struct SongDetailSection: View {

    let item: PreviewRecord

    @Query private var records: [SongRecord]

    @Upserter(\.song) private var syncer

    init(item: PreviewRecord) {
        self.item = item
        let previewID = item.id
        _records = Query(filter: #Predicate<SongRecord> { $0.previewID == previewID })
    }

    var body: some View {
        let song = records.first
        let artist = song?.artist ?? item.secondaryInfo
        Section {
            CatalogueItemHeader(
                title: song?.title ?? item.primaryInfo,
                artworkURL: song?.artworkURL ?? item.imageURL,
                credit: artist.isEmpty ? nil : "by \(artist)",
                info: { if let song { SongInfoLine(song: song) } },
                resourceURLs: song?.resourceURLs ?? item.externalLinks
            )
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
