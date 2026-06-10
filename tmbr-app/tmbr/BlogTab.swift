import SwiftUI
import SwiftData

struct BlogTab: View {

    @Query(sort: \PostRecord.createdAt, order: .reverse)
    private var posts: [PostRecord]

    @Blog(\.isSyncing)
    private var isSyncing

    @Environment(\.syncBlog)
    private var syncBlog

    @Environment(\.deletePost)
    private var deletePost

    @Environment(AuthState.self)
    private var authState

    @Environment(\.modelContext)
    private var modelContext

    @State private var showAccount = false
    @State private var showEditor = false
    @State private var postToEdit: PostRecord? = nil

    var body: some View {
        NavigationStack {
            List {
                if posts.isEmpty && isSyncing {
                    ContentUnavailableView("Loading…", systemImage: "arrow.trianglehead.2.clockwise")
                } else {
                    ForEach(posts) { post in
                        PostRow(post: post)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task { await deletePost(record: post, context: modelContext) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    postToEdit = post
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
            .navigationTitle("Blog")
            .toolbar {
#if os(iOS)
                if authState.isSignedIn {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { showEditor = true } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
#else
                if authState.isSignedIn {
                    ToolbarItem(placement: .automatic) {
                        Button { showEditor = true } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
#endif
                ToolbarItem(placement: .primaryAction) {
                    Button { showAccount = true } label: {
                        Image(systemName: authState.isSignedIn ? "person.circle.fill" : "person.circle")
                    }
                }
            }
        }
        .task { await syncBlog() }
        .sheet(isPresented: $showAccount) {
            AccountSheet()
                .environment(authState)
        }
        .sheet(isPresented: $showEditor) {
            BlogEditorView()
        }
        .sheet(item: $postToEdit) { post in
            BlogEditorView(post: post)
        }
    }
}

private struct PostRow: View {
    let post: PostRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(post.title.isEmpty ? "Untitled" : post.title)
            HStack {
                if post.syncState != .synced {
                    Image(systemName: "arrow.trianglehead.2.clockwise")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                Text(post.stateRaw.capitalized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(post.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
