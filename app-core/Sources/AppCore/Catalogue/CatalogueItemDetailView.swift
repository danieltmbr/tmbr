import SwiftUI
import SwiftData

/// Single navigation destination for all catalogue item types. A `switch` over `item.category`
/// (a `CatalogueItemType?`) embeds the matching per-type section (which fetches its typed record
/// from SwiftData by `previewID`), followed by a shared notes section.
///
/// Pull-to-refresh delegates to whichever typed section is currently visible: each section
/// publishes a `CatalogueItemRefreshKey` preference carrying a bound refresh closure, which the
/// `List` collects and runs. This way only the single-item endpoint for the visible type fires —
/// not the full catalogue sync.
struct CatalogueItemDetailView: View {

    let item: PreviewRecord

    /// Notes for this item only — filtered at the SQL level by the predicate-backed `@Query`
    /// built in `init`. The optional-typed `previewID` matches `NoteRecord.attachmentPreviewID: UUID?`.
    @Query private var notes: [NoteRecord]

    @State private var model = CatalogueItemDetailModel()

    init(item: PreviewRecord) {
        self.item = item
        let previewID: UUID? = item.id
        _notes = Query(
            filter: #Predicate<NoteRecord> { $0.attachmentPreviewID == previewID },
            sort: \.createdAt, order: .reverse
        )
    }

    var body: some View {
        List {
            typeSection
            CatalogueItemStatusLine(
                loading: model.loading,
                lastError: model.lastError,
                lastFetched: model.lastFetched
            )
            notesSection
        }
        .navigationTitle(item.primaryInfo)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onPreferenceChange(CatalogueItemRefreshKey.self) { [model] value in
            Task { @MainActor in model.setRefresh(value) }
        }
        .refreshable { await model.refresh() }
    }

    // MARK: - Type section

    @ViewBuilder
    private var typeSection: some View {
        switch item.category {
        case .song:
            SongDetailSection(previewID: item.id)
        case .album:
            AlbumDetailSection(previewID: item.id)
        case .playlist:
            PlaylistDetailSection(previewID: item.id)
        case .book:
            BookDetailSection(previewID: item.id)
        case .podcast:
            PodcastDetailSection(previewID: item.id)
        case .movie:
            MovieDetailSection(previewID: item.id)
        case nil:
            OrphanDetailSection(item: item)
        }
    }

    // MARK: - Notes section

    @ViewBuilder
    private var notesSection: some View {
        if !notes.isEmpty {
            Section("Notes") {
                ForEach(notes) { note in
                    MarkdownView(raw: note.body)
                        .padding(.vertical, 4)
                }
            }
        }
    }
}
