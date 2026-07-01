import Markdown

struct QuoteExtractor: MarkupWalker {

    private(set) var quotes: [String] = []
    
    private var currentQuote: String = ""
    
    private var isInsideQuote: Bool = false
    
    mutating func visitDocument(_ document: Document) -> () {
        quotes.removeAll()
        defaultVisit(document)
    }
    
    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> () {
        isInsideQuote = true
        descendInto(blockQuote)
        if !currentQuote.isEmpty {
            quotes.append(wrapAsBlockquote(currentQuote))
            currentQuote = ""
        }
        isInsideQuote = false
    }

    /// Converts extracted body text to valid blockquote markdown by prefixing every
    /// line with `> ` (blank paragraph-separator lines become bare `>`).
    ///
    /// Storing `Quote.body` as blockquote markdown means `CitationMarkdownFormatter`
    /// processes it in its natural context — cite spans and line breaks are rendered
    /// correctly without needing special round-trip encoding.
    private func wrapAsBlockquote(_ body: String) -> String {
        body.components(separatedBy: "\n")
            .map { $0.isEmpty ? ">" : "> \($0)" }
            .joined(separator: "\n")
    }

    /// Separates paragraphs within a blockquote with a blank line so the stored
    /// body round-trips through `HTMLFormatter` as distinct `<p>` blocks.
    mutating func visitParagraph(_ paragraph: Paragraph) -> () {
        guard isInsideQuote else {
            defaultVisit(paragraph)
            return
        }
        if !currentQuote.isEmpty {
            currentQuote.append("\n\n")
        }
        descendInto(paragraph)
    }

    mutating func visitInlineAttributes(_ attributes: InlineAttributes) -> () {
        if isInsideQuote {
            let outer = currentQuote
            currentQuote = ""
            descendInto(attributes)
            let inner = currentQuote
            currentQuote = outer
            // Cite spans are pre-converted to `class: citation` so HTMLFormatter renders
            // them with the correct CSS class. CitationMarkdownFormatter's source-range
            // lookup breaks for >-prefixed blockquote bodies (it finds `>` at col 1 rather
            // than `^[`, so extractContent returns "" and the span is never rewritten).
            let attrs = isCiteSpan(attributes.attributes) ? "class: citation" : attributes.attributes
            currentQuote.append("^[\(inner)](\(attrs))")
        } else {
            defaultVisit(attributes)
        }
    }

    private func isCiteSpan(_ attributes: String) -> Bool {
        attributes.range(of: #"\bcite\s*:"#, options: .regularExpression) != nil
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) -> () {
        guard isInsideQuote else { return }
        currentQuote.append("\\\n")
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> () {
        guard isInsideQuote else { return }
        // Promote soft breaks to hard breaks so consecutive > lines render as
        // <br /> rather than a browser-collapsed space after wrapAsBlockquote.
        currentQuote.append("\\\n")
    }
    
    mutating func visitText(_ text: Text) -> () {
        guard isInsideQuote else { return }
        currentQuote.append(text.string)
    }
}

extension Document {
    public var quotes: [String] {
        var walker = QuoteExtractor()
        walker.visitDocument(self)
        return walker.quotes
    }
}
