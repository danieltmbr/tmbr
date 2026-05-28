import SwiftUI

struct SearchTab: View {
    @State private var searchText = ""

    var body: some View {
        Group {
            if searchText.isEmpty {
                ContentUnavailableView(
                    "Search",
                    systemImage: "magnifyingglass",
                    description: Text("Posts, songs, books, movies, and more.")
                )
            } else {
                List(placeholderResults(for: searchText)) { result in
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
        .searchable(text: $searchText, prompt: "Posts, songs, books…")
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
