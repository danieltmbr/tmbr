import SwiftUI
import SwiftData
import TmbrCore

struct BlogEditorView: View {

    var post: PostRecord? = nil   // nil = create, non-nil = edit

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.createPost) private var createPost
    @Environment(\.updatePost) private var updatePost

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var state: PostState = .draft
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Title", text: $title, axis: .vertical)
                        .lineLimit(1...3)
                }
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
                Section {
                    Picker("Status", selection: $state) {
                        Text("Draft").tag(PostState.draft)
                        Text("Published").tag(PostState.published)
                    }
                }
            }
            .navigationTitle(post == nil ? "New Post" : "Edit Post")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
        .onAppear {
            if let post {
                title = post.title
                content = post.content
                state = PostState(rawValue: post.stateRaw) ?? .draft
            }
        }
    }

    private func save() async {
        isSaving = true
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        if let post {
            await updatePost(record: post, title: trimmedTitle, content: content, state: state)
        } else {
            await createPost(title: trimmedTitle, content: content, context: modelContext)
        }
        dismiss()
    }
}
