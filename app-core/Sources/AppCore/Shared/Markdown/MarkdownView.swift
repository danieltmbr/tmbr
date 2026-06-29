import SwiftUI
import TmbrCore

/// Renders a raw Markdown string as laid-out SwiftUI blocks — headings, lists, blockquotes,
/// code blocks, and inline formatting (bold, italic, links, code spans, citations).
///
/// Uses Foundation's `AttributedString` with `interpretedSyntax: .full` and the custom
/// `TmbrAttributes` scope so the web's inline-attribute convention (`htmltag`, `class`, `id`,
/// `cite`) is decoded alongside standard Foundation attributes. No third-party dependency.
///
/// Block layout (list indentation, blockquote bar, code background) is handled at the view
/// level; inline run styling is delegated to the `MarkdownDecorator` from the environment.
///
/// **Citations:** spans marked with `^[content](cite: kind)` are processed before rendering
/// by `MarkdownFootnotes`. The `citationPlacement` environment key controls whether they are
/// extracted to a numbered references section at the bottom (`.endOfDocument`) or left inline
/// as styled attributions (`.inline`).
///
/// **Anchor jumps:** fragment URLs (`#reference-N`) are intercepted internally and resolved
/// via `ScrollViewProxy` against the nearest enclosing `ScrollView`. No external wiring needed.
struct MarkdownView: View {

    let raw: String

    @Environment(\.markdownDecorator) private var decorator
    @Environment(\.citationPlacement) private var citationPlacement

    private var parsed: ParseResult { ParseResult.parse(raw, placement: citationPlacement) }

    var body: some View {
        let result = parsed
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 8) {
                ForEach(result.blocks, id: \.id) { block in
                    blockView(for: block)
                        .modifier(AnchorIDModifier(anchorID: block.anchorID))
                }
                if !result.references.isEmpty {
                    referencesSection(result.references)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.openURL, OpenURLAction { url in
                guard url.host == nil, let fragment = url.fragment else { return .systemAction }
                withAnimation { proxy.scrollTo(fragment, anchor: .top) }
                return .handled
            })
        }
    }

    // MARK: - References section

    @ViewBuilder
    private func referencesSection(_ references: [Citation]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
                .padding(.bottom, 4)
            ForEach(references, id: \.number) { citation in
                referenceRow(citation)
                    .id(citation.anchorID)
            }
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func referenceRow(_ citation: Citation) -> some View {
        let contentAttr: AttributedString = {
            let options = AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
            return (try? AttributedString(
                markdown: citation.content,
                including: AttributeScopes.TmbrAttributes.self,
                options: options
            )) ?? AttributedString(citation.content)
        }()

        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("\(citation.number).")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(minWidth: 16, alignment: .trailing)
            Text(contentAttr)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Block rendering

    @ViewBuilder
    private func blockView(for block: MarkdownBlock) -> some View {
        let content = decoratedAndStripped(block)
        switch block.kind {
        case .heading, .paragraph:
            TextBlock(content: content)
        case .listItem(let ordinal, let depth):
            ListItemBlock(content: content, ordinal: ordinal, depth: depth)
        case .blockQuote:
            QuoteBlock(content: content)
        case .codeBlock:
            CodeBlock(content: content)
        }
    }

    // MARK: - Decorate then strip

    /// Applies the injected decorator to each run (decorators can read `presentationIntent`
    /// for heading-level font selection), then strips `presentationIntent` so `Text` doesn't
    /// apply its own block layout on top of our block chrome.
    private func decoratedAndStripped(_ block: MarkdownBlock) -> AttributedString {
        var content = block.content
        let ranges = content.runs.map(\.range)
        for range in ranges {
            decorator(&content[range])
        }
        for range in ranges {
            content[range].presentationIntent = nil
        }
        return content
    }
}

// MARK: - Anchor ID modifier

private struct AnchorIDModifier: ViewModifier {
    let anchorID: String?
    func body(content: Content) -> some View {
        if let anchorID {
            content.id(anchorID)
        } else {
            content
        }
    }
}

// MARK: - Block views

private struct TextBlock: View {
    let content: AttributedString
    var body: some View {
        Text(content)
            .textSelection(.enabled)
    }
}

private struct ListItemBlock: View {
    let content: AttributedString
    let ordinal: Int?
    let depth: Int
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(ordinal.map { "\($0)." } ?? "•")
                .monospacedDigit()
                .frame(minWidth: 16, alignment: .trailing)
            Text(content)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, CGFloat(depth) * 12)
    }
}

private struct QuoteBlock: View {
    let content: AttributedString
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(.secondary.opacity(0.5))
                .frame(width: 3)
            Text(content)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }
}

private struct CodeBlock: View {
    let content: AttributedString
    var body: some View {
        Text(content)
            .font(.system(.body, design: .monospaced))
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            .textSelection(.enabled)
    }
}

// MARK: - ParseResult

private struct ParseResult {
    let blocks: [MarkdownBlock]
    let references: [Citation]

    static func parse(_ raw: String, placement: CitationPlacement) -> ParseResult {
        guard !raw.isEmpty else { return ParseResult(blocks: [], references: []) }

        // Rewrite cite spans in the raw string before AttributedString parsing —
        // Foundation does not apply custom inline attributes inside blockquotes.
        let footnotes = MarkdownFootnotes.process(raw, placement: placement)

        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .full,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        guard var attributed = try? AttributedString(
            markdown: footnotes.processed,
            including: AttributeScopes.TmbrAttributes.self,
            options: options
        ) else {
            let fallback = MarkdownBlock(id: 0, anchorID: nil, content: AttributedString(raw), kind: .paragraph)
            return ParseResult(blocks: [fallback], references: [])
        }

        // MarkdownFootnotes replaced cite spans with [N](#tmbr-footnote-N) links.
        // Foundation applies `link` correctly everywhere (including inside blockquotes), so
        // we can now find those placeholder links and swap in FootnoteMarkerAttribute — the
        // purely native attribute that the .footnote decorator reads for superscript styling.
        let markerRuns = attributed.runs.compactMap { run -> (Range<AttributedString.Index>, Int)? in
            guard let fragment = run.link?.fragment,
                  fragment.hasPrefix("tmbr-footnote-"),
                  let n = Int(fragment.dropFirst("tmbr-footnote-".count)) else { return nil }
            return (run.range, n)
        }
        for (range, n) in markerRuns {
            attributed[range][FootnoteMarkerAttribute.self] = n
            attributed[range].link = URL(string: "#\(Citation.anchorID(forNumber: n))")
        }

        return ParseResult(
            blocks: MarkdownBlock.grouped(attributed),
            references: footnotes.references
        )
    }
}


// MARK: - MarkdownBlock

private struct MarkdownBlock {

    let id: Int
    /// Populated from the `id:` custom inline attribute (`AnchorIDAttribute`). Used by
    /// `MarkdownView` to tag the block view with `.id(anchorID)` for `scrollTo` targets.
    let anchorID: String?
    /// Content still carries `presentationIntent` at this point — stripping happens in the
    /// view after the decorator runs so `.heading` can read the header level.
    let content: AttributedString
    let kind: Kind

    enum Kind {
        case heading(level: Int)
        case paragraph
        case listItem(ordinal: Int?, depth: Int)
        case blockQuote
        case codeBlock
    }

    // MARK: Grouping

    /// Groups runs by innermost block identity — each paragraph / heading / list item /
    /// blockquote gets one `MarkdownBlock`. Multiple runs sharing the same block (e.g. bold +
    /// normal text within one paragraph) are concatenated into a single `AttributedString`.
    static func grouped(_ attributed: AttributedString) -> [MarkdownBlock] {
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
            let anchorID = group.content.runs
                .compactMap { $0[AnchorIDAttribute.self] }
                .first
            return MarkdownBlock(
                id: group.id,
                anchorID: anchorID,
                content: group.content,
                kind: blockKind(for: group.intent)
            )
        }
    }

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
}
