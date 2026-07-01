import Testing
import WebCore
import Markdown
import Foundation

@Suite("Document.quotes using Core's QuoteExtractor")
struct QuoteExtractorTests {

    @Test("Single multi-line block quote is grouped into one entry")
    func singleQuoteBlock() async throws {
        let markdown = """
        Intro
        
        > This is a quote.
        > It spans multiple lines.
        
        Outro
        """
        
        let document = Document(parsing: markdown)
        let quotes = document.quotes

        #expect(quotes.count == 1)
        #expect(quotes[0] == "This is a quote.\\\nIt spans multiple lines.")
    }

    @Test("Two separate block quotes produce two entries")
    func multipleQuoteBlocks() async throws {
        let markdown = """
        > First
        
        Not a quote
        
        > Second line 1
        > Second line 2
        """
        
        let document = Document(parsing: markdown)
        let quotes = document.quotes
        
        #expect(quotes.count == 2)
        #expect(quotes[0].contains("First"))
        #expect(quotes[1] == "Second line 1\\\nSecond line 2")
    }
    
    @Test("Multi-paragraph block quote (blank > lines) preserves paragraph breaks")
    func multiParagraphQuote() async throws {
        let markdown = """
        > Már mióta pedig hogy ötösbe hajtok
        >
        > Sehol egy falu vagy akár egy város
        >
        > Hazafelé mikor érek én?
        """

        let document = Document(parsing: markdown)
        let quotes = document.quotes

        #expect(quotes.count == 1)
        // Each paragraph is separated by \n\n; lines within a paragraph end with \\n.
        #expect(quotes[0] == "Már mióta pedig hogy ötösbe hajtok\n\nSehol egy falu vagy akár egy város\n\nHazafelé mikor érek én?")
    }

    @Test("Decorators are removed from quoted text.")
    func undecorateQuote() async throws {
        let markdown = """
        Plain text followed by a quote with a strong attribute
        > I know it’s **scary** to bet on yourself, but if you don’t, nobody else will.
        """
        
        let document = Document(parsing: markdown)
        let quotes = document.quotes
        
        #expect(quotes.count == 1)
        #expect(quotes[0] == "I know it’s scary to bet on yourself, but if you don’t, nobody else will.")
    }
    
    @Test("References (a.k.a. inline attributes) are not removed from quoted text.")
    func unreferenceQuote() async throws {
        let markdown = """
        Plain text followed by a quote with a reference
        
        > I know it’s scary to bet on yourself, but if you don’t, nobody else will.^[[1](#reference-1)](class: reference-id, htmltag: sup)
        
        Then another plain text follwed by the reference itself
        
        ^[1: Barney Stinson, How I Met Your Mother, S4 E3](class: reference, id: reference-1)
        """
        
        let document = Document(parsing: markdown)
        let quotes = document.quotes
        
        #expect(quotes.count == 1)
        #expect(quotes[0] == "I know it’s scary to bet on yourself, but if you don’t, nobody else will.")
    }

    @Test("No block quotes yields empty array")
    func noQuotes() async throws {
        let markdownSource = """
        Hello
        World
        """

        let document = Document(parsing: markdownSource)
        let quotes = document.quotes

        #expect(quotes.isEmpty)
    }
}

// MARK: - Round-trip rendering

/// Ensures that `Quote.body` strings produced by `QuoteExtractor` round-trip through
/// `MarkdownFormatter` and produce the expected HTML line breaks. These tests guard
/// the end-to-end behaviour that was broken: multi-line quotes were rendering as a
/// single unbroken line because SoftBreak nodes are emitted as `\n` (not `<br />`)
/// by swift-markdown's `HTMLFormatter`.
@Suite("Quote body HTML round-trip")
struct QuoteHTMLRenderingTests {

    private let formatter = MarkdownFormatter.html(citationPlacement: .inline)

    @Test("Consecutive lines render with <br />")
    func consecutiveLinesRenderWithBreak() async throws {
        // This is the body QuoteExtractor now produces for consecutive > lines.
        let body = "I don't know where we going\\\nI don't know who we are\\\nI can feel your heartbeat"
        let html = formatter.format(body)

        #expect(html.contains("<br />"), "Expected <br /> for tight line breaks, got: \(html)")
        #expect(!html.contains("goingI"), "Lines must not be run together, got: \(html)")
    }

    @Test("Blank-line-separated paragraphs render as multiple <p> blocks")
    func multiparagraphRendersAsMultipleParagraphs() async throws {
        // This is the body QuoteExtractor now produces for blank->line-separated > blocks.
        let body = "Már mióta pedig hogy ötösbe hajtok\n\nSehol egy falu vagy akár egy város\n\nHazafelé mikor érek én?"
        let html = formatter.format(body)

        let pCount = html.components(separatedBy: "<p>").count - 1
        #expect(pCount >= 3, "Expected 3+ <p> elements for 3 paragraphs, got \(pCount) in: \(html)")
        #expect(!html.contains("hajtokSehol"), "Paragraphs must not be run together, got: \(html)")
    }

    @Test("Extracted body from tight multi-line blockquote round-trips to <br />")
    func extractionRoundTrip() async throws {
        let noteMarkdown = """
        > I know that you were not alone
        > But you're stealing my heart away
        """
        let quotes = Document(parsing: noteMarkdown).quotes
        #expect(quotes.count == 1)

        let html = formatter.format(quotes[0])
        #expect(html.contains("<br />"), "Expected <br /> in rendered HTML, got: \(html)")
    }

    @Test("Extracted body from multi-paragraph blockquote round-trips to multiple <p>")
    func multiParagraphExtractionRoundTrip() async throws {
        let noteMarkdown = """
        > Már mióta pedig hogy ötösbe hajtok
        >
        > Sehol egy falu vagy akár egy város
        """
        let quotes = Document(parsing: noteMarkdown).quotes
        #expect(quotes.count == 1)

        let html = formatter.format(quotes[0])
        let pCount = html.components(separatedBy: "<p>").count - 1
        #expect(pCount >= 2, "Expected 2+ <p> elements, got \(pCount) in: \(html)")
    }
}
