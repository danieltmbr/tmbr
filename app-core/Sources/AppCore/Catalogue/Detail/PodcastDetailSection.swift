import SwiftUI
import SwiftData
import AppPersistence

private struct PodcastInfoLine: View {
    let podcast: PodcastRecord

    var body: some View {
        if let text {
            Text(text).foregroundStyle(.secondary)
        }
    }

    private var text: String? {
        let parts = [seasonEpisode, podcast.genre, podcast.releaseDate?.formatted(date: .abbreviated, time: .omitted)]
            .compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private var seasonEpisode: String? {
        if let s = podcast.seasonNumber, let e = podcast.episodeNumber { return "S\(s):E\(e)" }
        if let e = podcast.episodeNumber { return "E\(e)" }
        return nil
    }
}

struct PodcastDetailSection: View {

    let item: PreviewRecord

    @Query private var records: [PodcastRecord]

    @Upserter(\.podcast) private var syncer

    init(item: PreviewRecord) {
        self.item = item
        let previewID = item.id
        _records = Query(filter: #Predicate<PodcastRecord> { $0.previewID == previewID })
    }

    var body: some View {
        let podcast = records.first
        let episodeTitle = podcast?.episodeTitle ?? item.secondaryInfo
        Section {
            CatalogueItemHeader(
                title: podcast?.title ?? item.primaryInfo,
                artworkURL: podcast?.artworkURL ?? item.imageURL,
                credit: episodeTitle.isEmpty ? nil : episodeTitle,
                info: { if let podcast { PodcastInfoLine(podcast: podcast) } },
                resourceURLs: podcast?.resourceURLs ?? item.externalLinks
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
