import SwiftUI

struct PostReaderView: View {
        
    let title: String
    
    let content: AttributedString
        
    let created: Date
    
    let published: Date?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.title.bold())
                Text((published ?? created).formatted(.publishDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(content)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}
