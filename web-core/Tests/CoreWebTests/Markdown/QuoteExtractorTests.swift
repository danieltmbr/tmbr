import Testing
import WebCore
import Markdown

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
        #expect(quotes[0] == "> This is a quote.\\\n> It spans multiple lines.")
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
        #expect(quotes[1] == "> Second line 1\\\n> Second line 2")
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
        #expect(quotes[0] == "> Már mióta pedig hogy ötösbe hajtok\n>\n> Sehol egy falu vagy akár egy város\n>\n> Hazafelé mikor érek én?")
    }

    @Test("Decorators are removed from quoted text.")
    func undecorateQuote() async throws {
        let markdown = """
        Plain text followed by a quote with a strong attribute
        > I know it's **scary** to bet on yourself, but if you don't, nobody else will.
        """

        let document = Document(parsing: markdown)
        let quotes = document.quotes

        #expect(quotes.count == 1)
        #expect(quotes[0] == "> I know it's scary to bet on yourself, but if you don't, nobody else will.")
    }

    @Test("References (a.k.a. inline attributes) are preserved in quoted text.")
    func unreferenceQuote() async throws {
        let markdown = """
        Plain text followed by a quote with a reference

        > I know it's scary to bet on yourself, but if you don't, nobody else will.^[[1](#reference-1)](class: reference-id, htmltag: sup)

        Then another plain text follwed by the reference itself

        ^[1: Barney Stinson, How I Met Your Mother, S4 E3](class: reference, id: reference-1)
        """

        let document = Document(parsing: markdown)
        let quotes = document.quotes

        #expect(quotes.count == 1)
        #expect(quotes[0].hasPrefix("> I know it's scary to bet on yourself"))
        #expect(quotes[0].contains("^["))
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
/// `MarkdownFormatter` and produce the expected HTML line breaks and citation styling.
@Suite("Quote body HTML round-trip")
struct QuoteHTMLRenderingTests {

    private let formatter = MarkdownFormatter.html(citationPlacement: .inline)

    @Test("Consecutive lines render with <br />")
    func consecutiveLinesRenderWithBreak() async throws {
        let noteMarkdown = """
        > I don't know where we going
        > I don't know who we are
        > I can feel your heartbeat
        """
        let quotes = Document(parsing: noteMarkdown).quotes
        #expect(quotes.count == 1)

        let html = formatter.format(quotes[0])
        #expect(html.contains("<br />"), "Expected <br /> for tight line breaks, got: \(html)")
        #expect(!html.contains("goingI"), "Lines must not be run together, got: \(html)")
    }

    @Test("Blank-line-separated paragraphs render as multiple <p> blocks")
    func multiparagraphRendersAsMultipleParagraphs() async throws {
        let noteMarkdown = """
        > Már mióta pedig hogy ötösbe hajtok
        >
        > Sehol egy falu vagy akár egy város
        >
        > Hazafelé mikor érek én?
        """
        let quotes = Document(parsing: noteMarkdown).quotes
        #expect(quotes.count == 1)

        let html = formatter.format(quotes[0])
        let pCount = html.components(separatedBy: "<p>").count - 1
        #expect(pCount >= 3, "Expected 3+ <p> elements for 3 paragraphs, got \(pCount) in: \(html)")
        #expect(!html.contains("hajtokSehol"), "Paragraphs must not be run together, got: \(html)")
    }

    @Test("Citation in blockquote renders with .citation class")
    func citationRenderTest() async throws {
        let noteMarkdown = """
        > There is nothing heroic about bullying yourself into submission. Be present and be patient with yourself.
        > ^[Andy Puddicombe, A Whole Run, Nike Run Club](cite: run)
        """
        let quotes = Document(parsing: noteMarkdown).quotes
        #expect(quotes.count == 1)

        let html = formatter.format(quotes[0])
        #expect(html.contains("class=\"citation\""), "Expected .citation span in: \(html)")
        #expect(!html.contains("cite: run"), "Raw cite attr should be rewritten, got: \(html)")
    }
}
