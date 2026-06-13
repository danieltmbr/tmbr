import SwiftUI
import SwiftData

struct CatalogueTab: View {

    @Query(sort: \CatalogueItemRecord.title)
    private var items: [CatalogueItemRecord]

    @Catalogue(\.isSyncing)
    private var isSyncing

    @Environment(\.syncCatalogue)
    private var syncCatalogue

    @Environment(AuthState.self)
    private var authState

    @State private var showAccount = false
    @State private var showFilter = false
    @State private var showTypePicker = false
    @State private var selectedType: CatalogueItemType?
    @State private var showEditor = false
    @State private var filterTypes: Set<CatalogueItemType> = []

    var body: some View {
        NavigationStack {
            List {
                if items.isEmpty && isSyncing {
                    ContentUnavailableView("Loading…", systemImage: "arrow.trianglehead.2.clockwise")
                } else {
                    ForEach(items) { item in
                        CatalogueItemRow(item: item)
                    }
                }
            }
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
