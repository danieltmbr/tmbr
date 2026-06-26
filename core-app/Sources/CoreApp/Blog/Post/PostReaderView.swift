import SwiftUI

struct PostReaderView: View {

    let title: String

    let content: String

    let created: Date

    let published: Date?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(.title.bold())
                    Text((published ?? created).formatted(.publishDate))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    MarkdownView(raw: content)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            // Intercept fragment URLs (e.g. `#reference-1`) for in-page anchor jumps.
            // External/internal links without a fragment fall through to the system handler.
            .environment(\.openURL, OpenURLAction { url in
                guard url.host == nil, let fragment = url.fragment else { return .systemAction }
                withAnimation { proxy.scrollTo(fragment, anchor: .top) }
                return .handled
            })
        }
        .navigationTitle(title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}
