import Testing
import WebCore

private let nbsp = "\u{00A0}"

@Suite("MarkdownFormatter keeps authored indentation")
struct MarkdownFormatterWhitespaceTests {

    @Test("Indented poem lines render with their leading whitespace inside the paragraph")
    func poem() {
        let markdown = """
        A   testem a konyhában,
        az elmém Hong Kong-ban
                      a Dragons Trail-en.

        A   szívem melletted — mindig,
          olykor hozzád simul,
        olykor       megretten
                    az elsötétült tánctéren.
        """

        let html = MarkdownFormatter.html.format(markdown)

        #expect(html == """
        <p>A   testem a konyhában,
        az elmém Hong Kong-ban
        \(String(repeating: nbsp, count: 14))a Dragons Trail-en.</p>
        <p>A   szívem melletted — mindig,
        \(nbsp)\(nbsp)olykor hozzád simul,
        olykor       megretten
        \(String(repeating: nbsp, count: 12))az elsötétült tánctéren.</p>

        """)
    }

    @Test("Soft breaks stay soft on the web — no <br> is introduced")
    func noHardBreaks() {
        let html = MarkdownFormatter.html.format("one\ntwo")
        #expect(html == "<p>one\ntwo</p>\n")
    }

    @Test("Indentation inside a block quote survives the citation pass")
    func blockQuoteWithCitation() {
        let markdown = """
        > The mind wanders,
        >       and wanders.
        > ^[Andy Puddicombe](cite: podcast)
        """

        let html = MarkdownFormatter.html.format(markdown)

        #expect(html.contains("The mind wanders,\n\(String(repeating: nbsp, count: 6))and wanders."))
        #expect(html.contains("id=\"reference-1\""))
    }

    @Test("Code blocks and lists are rendered exactly as before")
    func structuralBlocks() {
        let markdown = "- item\n  continued\n\n```\n    code\n```"
        let html = MarkdownFormatter.html.format(markdown)
        #expect(html.contains("item\ncontinued"))
        #expect(html.contains("<code>    code\n</code>"))
        #expect(!html.contains(nbsp))
    }
}
