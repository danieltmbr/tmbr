import SwiftUI

struct BlogTab: View {
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(placeholderPosts.enumerated()), id: \.offset) { index, title in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(index + 1).")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
#if os(macOS)
                        Text(title)
                        Spacer()
                        Text("May 28")
                            .foregroundStyle(.secondary)
#else
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                            Text("May 28")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
#endif
                    }
                }
            }
            .navigationTitle("Blog")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    AuthoringButton(systemImage: "square.and.pencil") { showEditor = true }
                }
#else
                ToolbarItem(placement: .automatic) {
                    AuthoringButton(systemImage: "square.and.pencil") { showEditor = true }
                }
#endif
                ToolbarItem(placement: .primaryAction) {
                    AccountButton()
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            BlogEditorView()
        }
    }

    private let placeholderPosts = [
        "On keeping a reading journal",
        "Why I stopped using recommendations",
        "Albums I return to every winter",
        "Notes on Detransition, Baby",
        "The case for private playlists",
    ]
}
