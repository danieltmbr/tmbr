import Testing
import Core
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
        #expect(quotes[0] == "This is a quote.\nIt spans multiple lines.")
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
        #expect(quotes[1] == "Second line 1\nSecond line 2")
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


