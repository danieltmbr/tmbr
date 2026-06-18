import SwiftUI
import SwiftData

struct BlogTab: View {

    @Query(sort: \PostRecord.createdAt, order: .reverse) 
    private var posts: [PostRecord]

    @Blog(\.phase) 
    private var phase

    @Environment(\.refreshBlog) 
    private var refreshBlog

    @State 
    private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(posts) { post in
                    NavigationLink {
                        PostDetailView(post: post)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.title)
                            Text(post.createdAt, format: .dateTime.month().day().year())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .overlay {
                if posts.isEmpty {
                    switch phase {
                    case .loading:
                        ProgressView()
                    case .failed(let message):
                        ContentUnavailableView("Couldn't load posts", systemImage: "wifi.slash", description: Text(message))
                    case .idle, .loaded:
                        ContentUnavailableView("No posts yet", systemImage: "doc.text")
                    }
                }
            }
            .navigationTitle("Blog")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    AuthoringButton(systemImage: "square.and.pencil") { showEditor = true }
                }
#else
                ToolbarItem(placement: .automatic) {
                    AuthoringButton(systemImage: "square.and.pencil") { showEditor = true }
                }
#endif
                ToolbarItem(placement: .primaryAction) {
                    AccountButton()
                }
            }
            .refreshable { await refreshBlog() }
        }
        .task { await refreshBlog() }
        .sheet(isPresented: $showEditor) {
            BlogEditorView()
        }
    }
}
