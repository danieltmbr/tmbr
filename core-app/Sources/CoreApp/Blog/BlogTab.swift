import SwiftUI
import SwiftData

struct BlogTab: View {

    @Query(sort: \PostRecord.createdAt, order: .reverse)
    private var posts: [PostRecord]

    @Environment(\.refreshBlog)
    private var refreshBlog

    @State
    private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                if !posts.isEmpty {
                    BlogStatusLine()
                }
                ForEach(posts) { post in
                    NavigationLink(value: post) {
                        PostCell(
                            title: post.title,
                            date: post.publishedAt ?? post.createdAt
                        )
                    }
                }
                if !posts.isEmpty {
                    BlogLoadMoreCell()
                }
            }
            .overlay {
                if posts.isEmpty {
                    BlogEmptyView()
                }
            }
            .navigationTitle("Blog")
            .navigationDestination(for: PostRecord.self) { post in
                PostReaderView(
                    title: post.title,
                    content: post.markdown ?? AttributedString(post.content),
                    created: post.createdAt,
                    published: post.publishedAt
                )
            }
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
            PostEditor()
        }
    }
}
