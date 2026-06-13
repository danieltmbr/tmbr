import SwiftUI
import SwiftData
import TmbrCore

struct NoteEditorView: View {

    let item: CatalogueItemRecord
    var note: NoteRecord? = nil   // nil = create, non-nil = edit

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.createNote) private var createNote
    @Environment(\.updateNote) private var updateNote

    @State private var noteText: String = ""
    @State private var access: Access = .private
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Note") {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 120)
                }
                Section {
                    Picker("Access", selection: $access) {
                        Text("Private").tag(Access.private)
                        Text("Public").tag(Access.public)
                    }
                }
            }
            .navigationTitle(note == nil ? "New Note" : "Edit Note")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(noteText.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
        .onAppear {
            if let note {
                noteText = note.body
                access = Access(rawValue: note.accessRaw) ?? .private
            }
        }
    }

    private func save() async {
        isSaving = true
        let trimmed = noteText.trimmingCharacters(in: .whitespaces)
        if let note {
            await updateNote(record: note, body: trimmed, access: access)
        } else {
            await createNote(body: trimmed, access: access, item: item, context: modelContext)
        }
        dismiss()
    }
}
