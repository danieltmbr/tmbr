import SwiftUI

struct SearchTab: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "Search",
                        systemImage: "magnifyingglass",
                        description: Text("Search across all posts and catalogue items.")
                    )
                } else {
                    List(placeholderResults(for: searchText)) { result in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 44, height: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.primaryInfo)
                                if let secondary = result.secondaryInfo {
                                    Text(secondary)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        }
        .tabItem {
            Label("Search", systemImage: "magnifyingglass")
        }
    }

    private struct SearchResult: Identifiable {
        let id = UUID()
        let primaryInfo: String
        let secondaryInfo: String?
    }

    private func placeholderResults(for query: String) -> [SearchResult] {
        [
            .init(primaryInfo: "The Glow Pt. 2", secondaryInfo: "The Microphones · Album"),
            .init(primaryInfo: "On keeping a reading journal", secondaryInfo: "Post"),
            .init(primaryInfo: "Stranger in the Alps", secondaryInfo: "Phoebe Bridgers · Album"),
            .init(primaryInfo: "Normal People", secondaryInfo: "Sally Rooney · Book"),
        ]
    }
}
