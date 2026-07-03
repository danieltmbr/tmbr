import SwiftUI
import SwiftData
import AppPersistence

struct CatalogueTab: View {

    @Environment(\.refreshCatalogue)
    private var refreshCatalogue

    @Environment(\.canAuthor)
    private var canAuthor

    @Catalogue(\.selectedCategorySlugs)
    private var selectedCategorySlugs

    @Preferences(\.selectedLanguages)
    private var selectedLanguages

    @State private var showFilter = false
    @State private var showTypePicker = false
    @State private var selectedType: CatalogueItemType?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            CatalogueItemsList(
                selectedCategorySlugs: selectedCategorySlugs,
                selectedLanguages: selectedLanguages
            )
            .navigationTitle("Catalogue")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button { showFilter = true } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    AuthoringButton(systemImage: "square.and.pencil") { showTypePicker = true }
                }
#else
                ToolbarItem(placement: .automatic) {
                    Button { showFilter = true } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                    .popover(isPresented: $showFilter) {
                        CatalogueFilterView()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    AuthoringButton(systemImage: "square.and.pencil") { showTypePicker = true }
                }
#endif
                ToolbarItem(placement: .primaryAction) {
                    AccountButton()
                }
            }
        }
        .task { await refreshCatalogue() }
#if os(iOS)
        .sheet(isPresented: $showFilter) {
            CatalogueFilterView()
        }
#endif
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

private struct CatalogueItemsList: View {

    @Query private var items: [PreviewRecord]

    @Environment(\.refreshCatalogue)
    private var refreshCatalogue

    init(selectedCategorySlugs: Set<String>, selectedLanguages: Set<Language>) {
        let slugs = Array(selectedCategorySlugs)
        let hasLanguageFilter = !selectedLanguages.isEmpty
        let wantsEn = selectedLanguages.contains(.en)
        let wantsHu = selectedLanguages.contains(.hu)
        _items = Query(
            filter: #Predicate { item in
                (slugs.isEmpty || slugs.contains(item.categoryType)) &&
                (!hasLanguageFilter ||
                 item.languagesJoined.isEmpty ||
                 (wantsEn && item.languagesJoined.contains("en")) ||
                 (wantsHu && item.languagesJoined.contains("hu")))
            },
            sort: \PreviewRecord.primaryInfo
        )
    }

    var body: some View {
        List {
            if !items.isEmpty {
                CatalogueStatusLine()
            }
            ForEach(items) { item in
                NavigationLink {
                    CatalogueItemDetailView(item: item)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.primaryInfo)
                        if let subtitle = item.secondaryInfo {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .overlay {
            if items.isEmpty {
                CatalogueEmptyView()
            }
        }
        .navigationDestination(for: CatalogueItemNavigation.self) { CatalogueItemNavigation.destination($0) }
        .refreshable { await refreshCatalogue() }
    }
}
