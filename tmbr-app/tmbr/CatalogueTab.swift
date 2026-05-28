import SwiftUI

struct CatalogueTab: View {
    @Environment(AuthState.self) private var authState
    @State private var showSignIn = false
    @State private var showFilter = false
    @State private var showTypePicker = false
    @State private var selectedType: CatalogueItemType?
    @State private var showEditor = false
    @State private var filterTypes: Set<CatalogueItemType> = []

    var body: some View {
        NavigationStack {
            List(placeholderItems) { item in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.primaryInfo)
                        Text(item.secondaryInfo)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("May 28")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Catalogue")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showFilter = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if authState.isSignedIn {
                        Button {
                            showTypePicker = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    } else {
                        Button("Sign In") {
                            showSignIn = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSignIn) {
            SignInView()
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
        .fullScreenCover(isPresented: $showEditor) {
            if let type = selectedType {
                MediaEditorView(type: type)
            }
        }
        .onChange(of: selectedType) { _, type in
            if type != nil { showEditor = true }
        }
        .onChange(of: authState.isSignedIn) { _, isSignedIn in
            if isSignedIn { showSignIn = false }
        }
        .tabItem {
            Label("Catalogue", systemImage: "square.grid.2x2")
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
