import SwiftUI

struct CatalogueTab: View {
    @Environment(AuthState.self) private var authState
    @State private var searchText = ""
    @State private var showSignIn = false
    @State private var showFilter = false
    @State private var showTypePicker = false
    @State private var selectedType: CatalogueItemType?
    @State private var showEditor = false
    @State private var filterTypes: Set<CatalogueItemType> = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<8) { i in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 48, height: 48)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Item Title \(i + 1)")
                                .font(.headline)
                            Text("Artist / Author")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("Catalogue")
            .searchable(text: $searchText)
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
            if type != nil {
                showEditor = true
            }
        }
        .tabItem {
            Label("Catalogue", systemImage: "square.grid.2x2")
        }
    }
}
