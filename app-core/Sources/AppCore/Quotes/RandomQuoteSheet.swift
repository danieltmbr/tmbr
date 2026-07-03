import SwiftUI
import AppPersistence

struct RandomQuoteSheet: View {

    let quotes: [QuoteRecord]

    @State private var current: QuoteRecord?

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        #if os(iOS)
        NavigationStack {
            quoteContent
                .navigationTitle("Random Quote")
                .toolbarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task { current = quotes.randomElement() }
        #else
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("Random Quote")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            Divider()

            quoteContent
        }
        .frame(minWidth: 400, minHeight: 300)
        .task { current = quotes.randomElement() }
        #endif
    }

    @ViewBuilder
    private var quoteContent: some View {
        if let current {
            ScrollView {
                VStack(alignment: .center, spacing: 16) {
                    MarkdownView(raw: current.body)
                        .multilineTextAlignment(.center)
                    Text(sourceFooter(for: current))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Shuffle Again") { pickNext() }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                }
                .padding()
            }
        } else {
            ContentUnavailableView("No Quotes", systemImage: "quote.bubble")
        }
    }

    private func sourceFooter(for quote: QuoteRecord) -> String {
        if let subtitle = quote.sourceSubtitle {
            return "From: \(quote.sourceTitle) · \(subtitle)"
        } else {
            return "From: \(quote.sourceTitle)"
        }
    }

    private func pickNext() {
        guard !quotes.isEmpty else { return }
        if quotes.count > 1, let current {
            self.current = quotes.filter { $0.serverID != current.serverID }.randomElement()
        } else {
            self.current = quotes.randomElement()
        }
    }
}
