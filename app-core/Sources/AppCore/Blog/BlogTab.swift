import SwiftUI
import SwiftData
import AppPersistence

struct BlogTab: View {

    @Environment(\.refreshBlog)
    private var refreshBlog

    @Preferences(\.selectedLanguages)
    private var selectedLanguages

    @State
    private var showEditor = false

    @State
    private var showLanguageFilter = false

    var body: some View {
        NavigationStack {
            PostsList(selectedLanguages: selectedLanguages)
                .navigationTitle("Blog")
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

private struct PostsList: View {

    @Query private var posts: [PostRecord]

    @Environment(\.refreshBlog)
    private var refreshBlog

    init(selectedLanguages: Set<Language>) {
        let codes = selectedLanguages.map(\.rawValue)
        _posts = Query(
            filter: #Predicate { post in
                codes.isEmpty || post.languageRaw.isEmpty || codes.contains(post.languageRaw)
            },
            sort: \PostRecord.createdAt,
            order: .reverse
        )
    }

    var body: some View {
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
        .navigationDestination(for: PostRecord.self) { post in
            PostReaderView(
                title: post.title,
                content: post.content,
                created: post.createdAt,
                published: post.publishedAt
            )
        }
        .refreshable { await refreshBlog() }
    }
}
