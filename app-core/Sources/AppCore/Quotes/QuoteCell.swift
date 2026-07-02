import SwiftUI
import AppPersistence

struct QuoteCell: View {

    let quote: QuoteRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            MarkdownView(raw: quote.body)
                .frame(maxHeight: 120, alignment: .top)
                .clipped()
            Text(sourceFooter)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var sourceFooter: String {
        if let subtitle = quote.sourceSubtitle {
            return "From: \(quote.sourceTitle) · \(subtitle)"
        } else {
            return "From: \(quote.sourceTitle)"
        }
    }
}
