import SwiftUI
import SwiftData

struct CatalogueTab: View {
    @Query(sort: \PreviewRecord.primaryInfo)
    private var allItems: [PreviewRecord]

    @Environment(\.refreshCatalogue)
    private var refreshCatalogue
    
    @Environment(\.canAuthor)
    private var canAuthor

    @State private var showFilter = false
    @State private var showTypePicker = false
    @State private var selectedType: CatalogueItemType?
    @State private var showEditor = false
    @State private var filterTypes: Set<CatalogueItemType> = []

    private var items: [PreviewRecord] {
        guard !filterTypes.isEmpty else { return allItems }
        let raw = Set(filterTypes.map(\.rawValue))
        return allItems.filter { raw.contains($0.categoryType) }
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
                }
                ToolbarItem(placement: .primaryAction) {
                    AuthoringButton(systemImage: "square.and.pencil") { showTypePicker = true }
                }
#endif
                ToolbarItem(placement: .primaryAction) {
                    AccountButton()
                }
            }
            .refreshable { await refreshCatalogue() }
        }
        .task { await refreshCatalogue() }
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
