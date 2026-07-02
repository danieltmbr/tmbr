import SwiftUI
import SwiftData
import AppPersistence

struct CatalogueTab: View {
    @Query(sort: \PreviewRecord.primaryInfo)
    private var allItems: [PreviewRecord]

    @Environment(\.refreshCatalogue)
    private var refreshCatalogue

    @Environment(\.canAuthor)
    private var canAuthor

    @Catalogue(\.selectedCategorySlugs)
    private var selectedCategorySlugs

    @State private var showFilter = false
    @State private var showTypePicker = false
    @State private var selectedType: CatalogueItemType?
    @State private var showEditor = false

    private var items: [PreviewRecord] {
        guard !selectedCategorySlugs.isEmpty else { return allItems }
        return allItems.filter { selectedCategorySlugs.contains($0.categoryType) }
    }

    var body: some View {
        NavigationStack {
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
            .navigationDestination(for: CatalogueItemNavigation.self) { CatalogueItemNavigation.destination($0) }
            .refreshable { await refreshCatalogue() }
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
