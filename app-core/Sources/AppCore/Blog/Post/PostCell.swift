import SwiftUI

struct PostCell: View {
    
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
        
    let title: String
    
    let date: Date

    var body: some View {
        if horizontalSizeClass == .compact {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(date.formatted(.publishDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                Spacer()
                Text(date.formatted(.publishDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
