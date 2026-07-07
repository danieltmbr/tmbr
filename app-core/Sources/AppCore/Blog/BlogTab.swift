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
            PostsList(
                term: searchText.isEmpty ? nil : searchText,
                selectedLanguages: selectedLanguages
            )
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
        // Network search is debounced 300 ms. When the term is cleared, fire an immediate
        // refresh so browse pagination resets cleanly (no stale search cursor).
        .task(id: searchText) {
            if searchText.isEmpty {
                await refreshBlog()
                return
            }
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

// MARK: - Unified list (browse and search)

private struct PostsList: View {

    @Query private var posts: [PostRecord]

    @Environment(\.refreshBlog)
    private var refreshBlog

    let isSearching: Bool

    init(term: String?, selectedLanguages: Set<Language>) {
        isSearching = term != nil
        _posts = Query(
            filter: term.map { PostRecord.search(term: $0, languages: selectedLanguages) }
                ?? PostRecord.list(languages: selectedLanguages),
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
                if isSearching {
                    ContentUnavailableView.search
                } else {
                    BlogEmptyView()
                }
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
        .refreshable {
            if !isSearching {
                await refreshBlog()
            }
        }
    }
}
