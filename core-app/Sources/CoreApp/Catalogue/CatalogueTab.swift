import SwiftUI

struct CatalogueTab: View {
    @Environment(\.canAuthor) private var canAuthor
    @Environment(\.accountToolbar) private var accountToolbar
    @State private var showFilter = false
    @State private var showTypePicker = false
    @State private var selectedType: CatalogueItemType?
    @State private var showEditor = false
    @State private var filterTypes: Set<CatalogueItemType> = []

    var body: some View {
        NavigationStack {
            List(placeholderItems) { item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.primaryInfo)
                    Text(item.secondaryInfo)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                if canAuthor {
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
                if canAuthor {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showTypePicker = true } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
#endif
                ToolbarItem(placement: .primaryAction) {
                    accountToolbar.content()
                }
            }
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

    private struct PreviewItem: Identifiable {
        let id = UUID()
        let primaryInfo: String
        let secondaryInfo: String
    }

    private let placeholderItems: [PreviewItem] = [
        .init(primaryInfo: "The Glow Pt. 2", secondaryInfo: "The Microphones"),
        .init(primaryInfo: "Parable of the Sower", secondaryInfo: "Octavia Butler"),
        .init(primaryInfo: "Stranger in the Alps", secondaryInfo: "Phoebe Bridgers"),
        .init(primaryInfo: "Arrival", secondaryInfo: "Denis Villeneuve"),
        .init(primaryInfo: "Radiolab", secondaryInfo: "Season 22, Ep. 4"),
        .init(primaryInfo: "Late Night Playlist", secondaryInfo: "Playlist"),
        .init(primaryInfo: "Normal People", secondaryInfo: "Sally Rooney"),
        .init(primaryInfo: "Javelin", secondaryInfo: "Sufjan Stevens"),
    ]
}
