import SwiftUI
import SwiftData
import AppPersistence
import TmbrCore

struct BlogTab: View {

    @Environment(\.refreshBlog)
    private var refreshBlog

    @Environment(\.searchBlog)
    private var searchBlog

    @Preferences(\.selectedLanguages)
    private var selectedLanguages

    @State
    private var searchText = ""

    @State
    private var showEditor = false

    @State
    private var showLanguageFilter = false

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    PostsList(selectedLanguages: selectedLanguages)
                } else {
                    PostsSearchList(term: searchText, selectedLanguages: selectedLanguages)
                }
            }
            .navigationTitle("Blog")
            .searchable(text: $searchText, prompt: "Search posts…")
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
        // Fire the network search whenever the term changes (debounced 300 ms).
        .task(id: searchText) {
            guard !searchText.isEmpty else { return }
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await searchBlog(term: searchText)
        }
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

// MARK: - Browse list (no search term)

private struct PostsList: View {

    @Query private var posts: [PostRecord]

    @Environment(\.refreshBlog)
    private var refreshBlog

    init(selectedLanguages: Set<Language>) {
        _posts = Query(
            filter: PostRecord.list(languages: selectedLanguages),
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

// MARK: - Search list (active search term)

private struct PostsSearchList: View {

    @Query private var posts: [PostRecord]

    init(term: String, selectedLanguages: Set<Language>) {
        _posts = Query(
            filter: PostRecord.search(term: term, languages: selectedLanguages),
            sort: \PostRecord.createdAt,
            order: .reverse
        )
    }

    var body: some View {
        List {
            ForEach(posts) { post in
                NavigationLink(value: post) {
                    PostCell(
                        title: post.title,
                        date: post.publishedAt ?? post.createdAt
                    )
                }
            }
        }
        .overlay {
            if posts.isEmpty {
                ContentUnavailableView.search
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
    }
}
