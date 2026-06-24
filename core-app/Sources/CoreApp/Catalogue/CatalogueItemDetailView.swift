import SwiftUI
import SwiftData

/// Reads cached records: the `PreviewRecord` projection + any notes anchored to it. Filtering notes in
/// memory by `attachmentPreviewID` (SwiftData mistranslates the optional-UUID `#Predicate`).
struct CatalogueItemDetailView: View {
    let item: PreviewRecord
    @Query(sort: \NoteRecord.createdAt, order: .reverse) private var allNotes: [NoteRecord]

    private var notes: [NoteRecord] {
        allNotes.filter { $0.attachmentPreviewID == item.id }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.primaryInfo)
                        .font(.title2.bold())
                    if let subtitle = item.secondaryInfo {
                        Text(subtitle)
                            .foregroundStyle(.secondary)
                    }
                    Text(item.categoryType.capitalized)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            if !notes.isEmpty {
                Section("Notes") {
                    ForEach(notes) { note in
                        Text(note.markdown ?? AttributedString(note.body))
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .navigationTitle(item.primaryInfo)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}
