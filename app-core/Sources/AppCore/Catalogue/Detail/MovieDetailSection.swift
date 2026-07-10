import SwiftUI
import SwiftData
import AppPersistence

private struct MovieInfoLine: View {
    let movie: MovieRecord

    var body: some View {
        if let text {
            Text(text).foregroundStyle(.secondary)
        }
    }

    private var text: String? {
        let parts = [movie.director, movie.genre, movie.releaseDate?.formatted(date: .abbreviated, time: .omitted)]
            .compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

struct MovieDetailSection: View {

    let item: PreviewRecord

    @Query private var records: [MovieRecord]

    @Upserter(.movie) private var syncer

    init(item: PreviewRecord) {
        self.item = item
        let previewID = item.id
        _records = Query(filter: #Predicate<MovieRecord> { $0.previewID == previewID })
    }

    var body: some View {
        let movie = records.first
        Section {
            CatalogueItemHeader(
                title: movie?.title ?? item.primaryInfo,
                artworkURL: movie?.coverURL ?? item.imageURL,
                info: { if let movie { MovieInfoLine(movie: movie) } },
                resourceURLs: movie?.resourceURLs ?? item.externalLinks
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
