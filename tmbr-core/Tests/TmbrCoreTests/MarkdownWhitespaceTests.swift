import Testing
import TmbrCore

private let nbsp = "\u{00A0}"

@Suite("MarkdownWhitespace — indentation")
struct MarkdownWhitespaceIndentationTests {

    private let whitespace = MarkdownWhitespace(preserving: .indentation)

    @Test("Indented poem lines keep their leading spaces as no-break spaces")
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

        let expected = """
        A   testem a konyhában,
        az elmém Hong Kong-ban
        \(String(repeating: nbsp, count: 14))a Dragons Trail-en.

        A   szívem melletted — mindig,
        \(nbsp)\(nbsp)olykor hozzád simul,
        olykor       megretten
        \(String(repeating: nbsp, count: 12))az elsötétült tánctéren.
        """

        #expect(whitespace.rewrite(markdown) == expected)
    }

    @Test("A paragraph's first line keeps up to three leading spaces")
    func firstLine() {
        #expect(whitespace.rewrite("   opening\nsecond") == "\(nbsp)\(nbsp)\(nbsp)opening\nsecond")
    }

    @Test("Four or more leading spaces on a block's first line is an indented code block")
    func indentedCodeBlock() {
        let markdown = "intro\n\n    code line\n      more code\n\nafter"
        #expect(whitespace.rewrite(markdown) == markdown)
    }

    @Test("Fenced code blocks pass through untouched, including indented closing fences")
    func fencedCodeBlock() {
        let markdown = "```swift\n    let x = 1\n  ```\n  outside"
        #expect(whitespace.rewrite(markdown) == "```swift\n    let x = 1\n  ```\n\(nbsp)\(nbsp)outside")
    }

    @Test("Tabs widen to the next multiple of four")
    func tabs() {
        #expect(whitespace.rewrite("a\n\tb\n  \tc") == "a\n\(String(repeating: nbsp, count: 4))b\n\(String(repeating: nbsp, count: 4))c")
    }

    @Test("Block quote markers are skipped and kept")
    func blockQuote() {
        let markdown = "> first\n>     indented\n>  one\nlazy"
        #expect(whitespace.rewrite(markdown) == "> first\n> \(String(repeating: nbsp, count: 4))indented\n> \(nbsp)one\nlazy")
    }

    @Test("Nested block quotes skip one marker per level")
    func nestedBlockQuote() {
        #expect(whitespace.rewrite("> > outer\n> >    inner") == "> > outer\n> > \(nbsp)\(nbsp)\(nbsp)inner")
    }

    @Test("A block quote opening with four spaces is an indented code block inside the quote")
    func blockQuoteCode() {
        let markdown = ">     code\n>     more"
        #expect(whitespace.rewrite(markdown) == markdown)
    }

    @Test("List items and their continuation lines are structural, not artistic")
    func lists() {
        let markdown = """
        - item one
          continues here
          - nested
        - item two

          second paragraph of item two
        1. ordered
           continues
        """
        #expect(whitespace.rewrite(markdown) == markdown)
    }

    @Test("Headings, thematic breaks and HTML blocks are untouched")
    func otherBlocks() {
        let markdown = " # heading\n\n  ---\n\n <div>\n   inside\n </div>\n\n  text"
        #expect(whitespace.rewrite(markdown) == " # heading\n\n  ---\n\n <div>\n   inside\n </div>\n\n\(nbsp)\(nbsp)text")
    }

    @Test("A heading or list can interrupt a paragraph")
    func interruptions() {
        let markdown = "text\n  # heading\n   - item\n  after list"
        #expect(whitespace.rewrite(markdown) == markdown)
    }

    @Test("Setext underlines stay underlines")
    func setext() {
        let markdown = "Title\n  ===\n\nSub\n ---\n  para"
        #expect(whitespace.rewrite(markdown) == "Title\n  ===\n\nSub\n ---\n\(nbsp)\(nbsp)para")
    }

    @Test("Windows line endings are normalised and still handled")
    func crlf() {
        #expect(whitespace.rewrite("a\r\n  b\r\n") == "a\n\(nbsp)\(nbsp)b\n")
    }

    @Test("Unindented prose is returned verbatim")
    func verbatim() {
        let markdown = "Plain paragraph\nwith two lines.\n\n## Heading\n\n1. one\n2. two\n"
        #expect(whitespace.rewrite(markdown) == markdown)
    }
}

@Suite("MarkdownWhitespace — line breaks")
struct MarkdownWhitespaceLineBreakTests {

    private let whitespace = MarkdownWhitespace(preserving: .lineBreaks)

    @Test("Soft breaks inside a paragraph become backslash hard breaks")
    func paragraph() {
        #expect(whitespace.rewrite("one\ntwo\nthree\n\nfour\nfive") == "one\\\ntwo\\\nthree\n\nfour\\\nfive")
    }

    @Test("Existing hard breaks are not doubled")
    func existingHardBreaks() {
        #expect(whitespace.rewrite("one\\\ntwo  \nthree\nfour") == "one\\\ntwo  \nthree\\\nfour")
    }

    @Test("Block quote lines get hard breaks; the markers stay")
    func blockQuote() {
        #expect(whitespace.rewrite("> one\n> two\n>\n> three") == "> one\\\n> two\n>\n> three")
    }

    @Test("Lists, code and headings are left alone")
    func nonParagraphs() {
        let markdown = "- a\n  b\n\n```\nx\ny\n```\n\n# h\ntext\nmore"
        #expect(whitespace.rewrite(markdown) == "- a\n  b\n\n```\nx\ny\n```\n\n# h\ntext\\\nmore")
    }

    @Test("A setext heading is not broken by a trailing backslash")
    func setext() {
        #expect(whitespace.rewrite("Title\n===\nbody\nmore") == "Title\n===\nbody\\\nmore")
    }
}

@Suite("MarkdownWhitespace — combined")
struct MarkdownWhitespaceCombinedTests {

    @Test("Indentation and line breaks compose")
    func both() {
        let whitespace = MarkdownWhitespace(preserving: [.indentation, .lineBreaks])
        #expect(whitespace.rewrite("a\n    b\nc") == "a\\\n\(String(repeating: nbsp, count: 4))b\\\nc")
    }

    @Test("No preservation means no change")
    func none() {
        #expect(MarkdownWhitespace(preserving: []).rewrite("a\r\n  b") == "a\r\n  b")
    }
}
