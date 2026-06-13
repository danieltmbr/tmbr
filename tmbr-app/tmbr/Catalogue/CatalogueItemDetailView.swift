import SwiftUI
import SwiftData
import TmbrCore

struct CatalogueItemDetailView: View {

    let item: CatalogueItemRecord

    @Environment(\.modelContext) private var modelContext
    @Environment(\.deleteNote) private var deleteNote

    @State private var showNoteEditor = false
    @State private var noteToEdit: NoteRecord? = nil

    private var notes: [NoteRecord] {
        let sourceID = item.sourceID
        let categoryType = item.categoryType
        let all = (try? modelContext.fetch(FetchDescriptor<NoteRecord>())) ?? []
        return all.filter { $0.attachmentSourceID == sourceID && $0.attachmentCategoryType == categoryType }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .foregroundStyle(.secondary)
                    }
                    Text(item.categoryType.capitalized)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }

            Section("Notes") {
                if notes.isEmpty {
                    Text("No notes yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(notes) { note in
                        NoteRow(note: note)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await deleteNote(record: note, context: modelContext) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .onTapGesture {
                                noteToEdit = note
                            }
                    }
                }
            }
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    noteToEdit = nil
                    showNoteEditor = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showNoteEditor) {
            NoteEditorView(item: item)
        }
        .sheet(item: $noteToEdit) { note in
            NoteEditorView(item: item, note: note)
        }
    }
}

private struct NoteRow: View {
    let note: NoteRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.body)
                .lineLimit(3)
            HStack {
                if note.syncState != .synced {
                    Image(systemName: "arrow.trianglehead.2.clockwise")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                Text(note.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(note.accessRaw)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
