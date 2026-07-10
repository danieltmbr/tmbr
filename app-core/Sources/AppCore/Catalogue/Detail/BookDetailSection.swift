import SwiftUI
import SwiftData
import AppPersistence

private struct BookInfoLine: View {
    let book: BookRecord

    var body: some View {
        if let text {
            Text(text).foregroundStyle(.secondary)
        }
    }

    private var text: String? {
        let parts = [book.genre, book.releaseDate?.formatted(date: .abbreviated, time: .omitted)]
            .compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

struct BookDetailSection: View {

    let item: PreviewRecord

    @Query
    private var records: [BookRecord]

    @Upserter(.book)
    private var syncer

    init(item: PreviewRecord) {
        self.item = item
        let previewID = item.id
        _records = Query(filter: #Predicate<BookRecord> { $0.previewID == previewID })
    }

    var body: some View {
        let book = records.first
        let author = book?.author ?? item.secondaryInfo
        Section {
            CatalogueItemHeader(
                title: book?.title ?? item.primaryInfo,
                artworkURL: book?.coverURL ?? item.imageURL,
                credit: author.isEmpty ? nil : "by \(author)",
                info: { if let book { BookInfoLine(book: book) } },
                resourceURLs: book?.resourceURLs ?? item.externalLinks
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
