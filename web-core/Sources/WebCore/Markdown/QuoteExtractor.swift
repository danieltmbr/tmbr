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
            quotes.append(currentQuote)
            currentQuote = ""
        }
        isInsideQuote = false
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
            // Reconstruct ^[...](attr) syntax so the body is renderable markdown
            let outer = currentQuote
            currentQuote = ""
            descendInto(attributes)
            let inner = currentQuote
            currentQuote = outer
            currentQuote.append("^[\(inner)](\(attributes.attributes))")
        } else {
            defaultVisit(attributes)
        }
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) -> () {
        guard isInsideQuote else { return }
        // Store as a CommonMark hard break so re-parsing yields a LineBreak node,
        // which HTMLFormatter renders as <br /> rather than a collapsible whitespace.
        currentQuote.append("\\\n")
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> () {
        guard isInsideQuote else { return }
        // Same as visitLineBreak — promote soft breaks to hard breaks so the
        // stored body renders with <br /> rather than a space in HTML.
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
