import SwiftUI
import SwiftData
import AppPersistence

struct BlogTab: View {

    @Query(sort: \PostRecord.createdAt, order: .reverse)
    private var allPosts: [PostRecord]

    @Environment(\.refreshBlog)
    private var refreshBlog

    @Preferences(\.selectedLanguages)
    private var selectedLanguages

    @State
    private var showEditor = false

    @State
    private var showLanguageFilter = false

    private var posts: [PostRecord] {
        guard !selectedLanguages.isEmpty else { return allPosts }
        return allPosts.filter { post in
            guard let lang = post.language else { return true }
            return selectedLanguages.contains(lang)
        }
    }

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
                    content: post.content,
                    created: post.createdAt,
                    published: post.publishedAt
                )
            }
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button { showLanguageFilter = true } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    AuthoringButton(systemImage: "square.and.pencil") { showEditor = true }
                }
#else
                ToolbarItem(placement: .automatic) {
                    Button { showLanguageFilter = true } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                    .popover(isPresented: $showLanguageFilter) {
                        LanguageFilterView()
                    }
                }
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
#if os(iOS)
        .sheet(isPresented: $showLanguageFilter) {
            LanguageFilterView()
        }
#endif
        .sheet(isPresented: $showEditor) {
            PostEditor()
        }
    }
}
