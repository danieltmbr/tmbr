import SwiftUI
import Foundation

/// Renders a raw Markdown string as laid-out SwiftUI blocks — headings, lists, blockquotes,
/// code blocks, and inline formatting (bold, italic, links, code spans). Uses Foundation's
/// `AttributedString` with `interpretedSyntax: .full`; no third-party dependency.
///
/// Falls back to unstyled `Text` if markdown parsing fails.
struct MarkdownView: View {

    let raw: String

    private var blocks: [MarkdownBlock] { MarkdownBlock.parse(raw) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(blocks, id: \.id) { block in
                blockView(for: block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Block rendering

    @ViewBuilder
    private func blockView(for block: MarkdownBlock) -> some View {
        switch block.kind {
        case .heading(let level):
            Text(block.content)
                .font(headingFont(level))
                .textSelection(.enabled)

        case .paragraph:
            Text(block.content)
                .textSelection(.enabled)

        case .listItem(let ordinal, let depth):
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(ordinal.map { "\($0)." } ?? "•")
                    .monospacedDigit()
                    .frame(minWidth: 16, alignment: .trailing)
                Text(block.content)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, CGFloat(depth) * 12)

        case .blockQuote:
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.secondary.opacity(0.5))
                    .frame(width: 3)
                Text(block.content)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

        case .codeBlock:
            Text(block.content)
                .font(.system(.body, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                .textSelection(.enabled)
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .title.bold()
        case 2: return .title2.bold()
        case 3: return .title3.bold()
        default: return .headline
        }
    }
}

// MARK: - MarkdownBlock

private struct MarkdownBlock {

    let id: Int
    let content: AttributedString
    let kind: Kind

    enum Kind {
        case heading(level: Int)
        case paragraph
        case listItem(ordinal: Int?, depth: Int)
        case blockQuote
        case codeBlock
    }

    // MARK: Parsing

    static func parse(_ raw: String) -> [MarkdownBlock] {
        guard !raw.isEmpty else { return [] }
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .full,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        guard let attributed = try? AttributedString(markdown: raw, options: options) else {
            return [MarkdownBlock(id: 0, content: AttributedString(raw), kind: .paragraph)]
        }
        return grouped(attributed)
    }

    /// Groups runs by innermost block identity — each paragraph / heading / list item /
    /// blockquote gets one `MarkdownBlock`. Multiple runs sharing the same block (e.g. bold +
    /// normal text within one paragraph) are concatenated into a single `AttributedString`.
    private static func grouped(_ attributed: AttributedString) -> [MarkdownBlock] {
        struct Group {
            let id: Int
            var content: AttributedString
            let intent: PresentationIntent?
        }

        var groups: [Group] = []
        var idToIndex: [Int: Int] = [:]
        var nextFallback = 1_000_000

        for run in attributed.runs {
            let intent = run.presentationIntent
            let id: Int
            if let last = intent?.components.last {
                id = last.identity
            } else {
                id = nextFallback
                nextFallback += 1
            }

            let runContent = AttributedString(attributed[run.range])

            if let idx = idToIndex[id] {
                groups[idx].content += runContent
            } else {
                idToIndex[id] = groups.count
                groups.append(Group(id: id, content: runContent, intent: intent))
            }
        }

        return groups.map { group in
            MarkdownBlock(
                id: group.id,
                content: strippingBlockIntent(group.content),
                kind: blockKind(for: group.intent)
            )
        }
    }

    /// Determines the block kind from the `PresentationIntent` component hierarchy
    /// (outermost → innermost, following `components` ordering).
    private static func blockKind(for intent: PresentationIntent?) -> Kind {
        guard let intent else { return .paragraph }

        var headingLevel: Int?
        var isCode = false
        var isBlockQuote = false
        var isList = false
        var isOrdered = false
        var listOrdinal: Int?

        for component in intent.components {
            switch component.kind {
            case .header(level: let level):
                headingLevel = level
            case .codeBlock(languageHint: _):
                isCode = true
            case .blockQuote:
                isBlockQuote = true
            case .orderedList:
                isList = true
                isOrdered = true
            case .unorderedList:
                isList = true
            case .listItem(ordinal: let ordinal):
                listOrdinal = ordinal
            default:
                break
            }
        }

        if let level = headingLevel { return .heading(level: level) }
        if isCode { return .codeBlock }
        if isList { return .listItem(ordinal: isOrdered ? listOrdinal : nil, depth: intent.indentationLevel) }
        if isBlockQuote { return .blockQuote }
        return .paragraph
    }

    /// Removes `presentationIntent` from all runs so `Text` doesn't apply its own block layout
    /// on top of our custom block rendering while still honouring inline attributes (bold, italic…).
    private static func strippingBlockIntent(_ content: AttributedString) -> AttributedString {
        var result = content
        let ranges = Array(content.runs.compactMap { run -> Range<AttributedString.Index>? in
            run.presentationIntent != nil ? run.range : nil
        })
        for range in ranges {
            result[range].presentationIntent = nil
        }
        return result
    }
}
