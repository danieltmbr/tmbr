import SwiftUI

/// Reads the cached `PostRecord` — the list response already carries the full `content`. No per-item
/// fetch (no public detail endpoint yet); a per-screen refresh seam lands when one does.
struct PostDetailView: View {
    
    let post: PostRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(post.title)
                    .font(.title.bold())
                Text((post.publishedAt ?? post.createdAt).formatted(.publishDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text((try? AttributedString(markdown: post.content)) ?? AttributedString(post.content))
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(post.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}
