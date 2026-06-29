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
    
    mutating func visitInlineAttributes(_ attributes: InlineAttributes) -> () {
        guard !isInsideQuote else { return }
        defaultVisit(attributes)
    }
    
    mutating func visitLineBreak(_ lineBreak: LineBreak) -> () {
        guard isInsideQuote else { return }
        currentQuote.append("\n")
    }
    
    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> () {
        guard isInsideQuote else { return }
        currentQuote.append("\n")
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
