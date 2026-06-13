import SwiftUI
import SwiftData

struct CatalogueTab: View {

    @Query(sort: \CatalogueItemRecord.title)
    private var items: [CatalogueItemRecord]

    @Catalogue(\.isSyncing)     private var isSyncing
    @Catalogue(\.syncError)     private var syncError
    @Catalogue(\.hasMoreItems)  private var hasMoreItems
    @Catalogue(\.isLoadingMore) private var isLoadingMore

    @Environment(\.syncCatalogue)           private var syncCatalogue
    @Environment(\.loadMoreCatalogueItems)  private var loadMoreCatalogueItems
    @Environment(AuthState.self)            private var authState

    @State private var showAccount = false
    @State private var showFilter = false
    @State private var showTypePicker = false
    @State private var selectedType: CatalogueItemType?
    @State private var showEditor = false
    @State private var filterTypes: Set<CatalogueItemType> = []

    var body: some View {
        NavigationStack {
            List {
                syncErrorBanner

                if items.isEmpty && isSyncing {
                    ContentUnavailableView("Loading…", systemImage: "arrow.trianglehead.2.clockwise")
                } else {
                    ForEach(items) { item in
                        NavigationLink(destination: CatalogueItemDetailView(item: item)) {
                            CatalogueItemRow(item: item)
                        }
                    }

                    if hasMoreItems {
                        loadMoreRow
                    }
                }
            }
            .refreshable { await syncCatalogue() }
            .navigationTitle("Catalogue")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button { showFilter = true } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                }
                if authState.isSignedIn {
                    ToolbarSpacer(.fixed, placement: .topBarLeading)
                    ToolbarItem(placement: .topBarLeading) {
                        Button { showTypePicker = true } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
#else
                ToolbarItem(placement: .automatic) {
                    Button { showFilter = true } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                }
                if authState.isSignedIn {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showTypePicker = true } label: {
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
        .task { await syncCatalogue() }
        .sheet(isPresented: $showAccount) {
            AccountSheet()
                .environment(authState)
        }
        .sheet(isPresented: $showFilter) {
            CatalogueFilterSheet(selectedTypes: $filterTypes)
        }
        .sheet(isPresented: $showTypePicker) {
            MediaTypePickerSheet { type in
                selectedType = type
            }
        }
        .sheet(isPresented: $showEditor) {
            if let type = selectedType {
                MediaEditorView(type: type)
            }
        }
        .onChange(of: selectedType) { _, type in
            if type != nil { showEditor = true }
        }
    }

    @ViewBuilder private var syncErrorBanner: some View {
        if let error = syncError {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Retry") { Task { await syncCatalogue() } }
                    .font(.caption)
            }
            .listRowBackground(Color.orange.opacity(0.1))
        }
    }

    @ViewBuilder private var loadMoreRow: some View {
        HStack {
            Spacer()
            if isLoadingMore {
                ProgressView()
            } else {
                Button("Load Older Items") {
                    Task { await loadMoreCatalogueItems() }
                }
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .task { await loadMoreCatalogueItems() }
    }
}

private struct CatalogueItemRow: View {
    let item: CatalogueItemRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.title)
            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
