/// Rewrites Markdown source so whitespace an author placed inside a paragraph survives parsing.
///
/// CommonMark strips the leading whitespace of every paragraph line and treats a single
/// newline as a soft break. Both are lost on purpose for prose, but a poem or lyric relies on
/// them. This rewriter runs on the raw source before any parser sees it, so the web
/// (swift-markdown) and the native app (Foundation's `AttributedString`) render the same
/// shape from the same code.
///
/// Only paragraph lines are touched. Fenced and indented code blocks, lists, headings,
/// thematic breaks and HTML blocks pass through unchanged. Block quote markers are skipped
/// before a line is inspected and put back afterwards.
///
/// - ``Preservation/indentation`` replaces leading spaces/tabs with no-break spaces (U+00A0),
///   which CommonMark does not strip. Pair it with `white-space: pre-wrap` on the web.
/// - ``Preservation/lineBreaks`` ends a paragraph line with a backslash when the next line
///   continues the same paragraph, turning the soft break into a hard one. The web does not
///   need this (`pre-wrap` already shows the newline); Foundation's parser does.
public struct MarkdownWhitespace: Sendable {

    public struct Preservation: OptionSet, Sendable {
        public let rawValue: UInt8
        public init(rawValue: UInt8) { self.rawValue = rawValue }

        /// Keep leading whitespace on paragraph lines.
        public static let indentation = Preservation(rawValue: 1 << 0)
        /// Keep single newlines inside a paragraph as visible line breaks.
        public static let lineBreaks = Preservation(rawValue: 1 << 1)
    }

    public let preservation: Preservation

    public init(preserving preservation: Preservation) {
        self.preservation = preservation
    }

    public func rewrite(_ markdown: String) -> String {
        guard !preservation.isEmpty, !markdown.isEmpty else { return markdown }

        var scanner = Scanner()
        let lines = markdown
            .split(omittingEmptySubsequences: false, whereSeparator: { $0 == "\n" || $0 == "\r\n" || $0 == "\r" })
            .map { scanner.classify($0) }

        var output: [String] = []
        output.reserveCapacity(lines.count)
        for (index, line) in lines.enumerated() {
            var text = line.text(preservingIndentation: preservation.contains(.indentation))
            if preservation.contains(.lineBreaks),
               line.role.isParagraph,
               index + 1 < lines.count,
               lines[index + 1].role == .paragraphContinuation,
               !text.hasSuffix("\\"),
               !text.hasSuffix("  ") {
                text.append("\\")
            }
            output.append(text)
        }
        return output.joined(separator: "\n")
    }
}

// MARK: - Line classification

private extension MarkdownWhitespace {

    enum Role: Equatable {
        case paragraphStart
        case paragraphContinuation
        case other

        var isParagraph: Bool { self != .other }
    }

    struct Line {
        let role: Role
        /// Block quote markers (and their surrounding spaces) preceding the content.
        let prefix: Substring
        /// Leading spaces/tabs of the content.
        let indentation: Substring
        /// The content after its indentation.
        let body: Substring

        func text(preservingIndentation: Bool) -> String {
            guard preservingIndentation, role.isParagraph, !indentation.isEmpty else {
                return String(prefix) + String(indentation) + String(body)
            }
            let width = indentation.reduce(0) { column, character in
                character == "\t" ? column + 4 - column % 4 : column + 1
            }
            return String(prefix) + String(repeating: "\u{00A0}", count: width) + String(body)
        }
    }

    enum Block {
        case none, paragraph, list, indentedCode, fencedCode, html, other
    }

    /// Tracks enough block structure, line by line, to tell paragraph text from everything else.
    struct Scanner {
        private var block: Block = .none
        private var blockDepth = 0
        private var blankSinceBlock = true
        private var fence: (marker: Character, length: Int, depth: Int)?

        mutating func classify(_ raw: Substring) -> Line {
            let (prefix, content, depth) = Self.splitBlockQuoteMarkers(raw)
            let indentation = content.prefix { $0 == " " || $0 == "\t" }
            let body = content[indentation.endIndex...]
            let indentWidth = indentation.reduce(0) { column, character in
                character == "\t" ? column + 4 - column % 4 : column + 1
            }
            let other = Line(role: .other, prefix: prefix, indentation: indentation, body: body)

            if let fence {
                if depth == fence.depth, indentWidth < 4, Self.isClosingFence(body, fence) {
                    self.fence = nil
                    block = .other
                    blankSinceBlock = false
                }
                return other
            }

            if body.isEmpty {
                blankSinceBlock = true
                return other
            }

            // A paragraph continues on the next non-blank line unless something interrupts it.
            if block == .paragraph, !blankSinceBlock, depth <= blockDepth {
                let interrupts = indentWidth < 4 && (
                    Self.isListMarker(body) || Self.isATXHeading(body) || Self.isFence(body) != nil
                    || Self.isThematicBreak(body) || body.first == "<"
                )
                if !interrupts {
                    if indentWidth < 4, Self.isSetextUnderline(body) {
                        block = .other
                        return other
                    }
                    return Line(role: .paragraphContinuation, prefix: prefix, indentation: indentation, body: body)
                }
            }

            // Lines that stay inside a non-paragraph block.
            if depth == blockDepth {
                switch block {
                case .list where !blankSinceBlock || indentWidth >= 2:
                    return other
                case .indentedCode where indentWidth >= 4:
                    return other
                case .html where !blankSinceBlock:
                    return other
                default:
                    break
                }
            }

            // A new block starts here.
            blockDepth = depth
            blankSinceBlock = false
            if indentWidth < 4, let opened = Self.isFence(body) {
                fence = (opened.marker, opened.length, depth)
                block = .fencedCode
                return other
            }
            if indentWidth >= 4 {
                block = .indentedCode
                return other
            }
            if Self.isListMarker(body) {
                block = .list
                return other
            }
            if Self.isATXHeading(body) || Self.isThematicBreak(body) {
                block = .other
                return other
            }
            if body.first == "<" {
                block = .html
                return other
            }
            block = .paragraph
            return Line(role: .paragraphStart, prefix: prefix, indentation: indentation, body: body)
        }

        // MARK: Syntax probes

        /// Peels `up to 3 spaces` + `>` + `optional space` off the line as many times as it
        /// appears, returning the consumed prefix, the remaining content and the nesting depth.
        private static func splitBlockQuoteMarkers(_ line: Substring) -> (prefix: Substring, content: Substring, depth: Int) {
            var index = line.startIndex
            var depth = 0
            while true {
                var probe = index
                var spaces = 0
                while probe < line.endIndex, line[probe] == " ", spaces < 3 {
                    spaces += 1
                    line.formIndex(after: &probe)
                }
                guard probe < line.endIndex, line[probe] == ">" else { break }
                line.formIndex(after: &probe)
                if probe < line.endIndex, line[probe] == " " {
                    line.formIndex(after: &probe)
                }
                index = probe
                depth += 1
            }
            return (line[..<index], line[index...], depth)
        }

        private static func isListMarker(_ body: Substring) -> Bool {
            guard let first = body.first else { return false }
            if "-*+".contains(first) {
                return Self.isSpaceOrEnd(body.dropFirst())
            }
            let digits = body.prefix { $0.isASCII && $0.isNumber }
            guard (1...9).contains(digits.count) else { return false }
            let rest = body[digits.endIndex...]
            guard let delimiter = rest.first, delimiter == "." || delimiter == ")" else { return false }
            return Self.isSpaceOrEnd(rest.dropFirst())
        }

        private static func isATXHeading(_ body: Substring) -> Bool {
            let hashes = body.prefix { $0 == "#" }
            guard (1...6).contains(hashes.count) else { return false }
            return Self.isSpaceOrEnd(body[hashes.endIndex...])
        }

        private static func isThematicBreak(_ body: Substring) -> Bool {
            let marks = body.filter { $0 != " " && $0 != "\t" }
            guard marks.count >= 3, let first = marks.first, "-*_".contains(first) else { return false }
            return marks.allSatisfy { $0 == first }
        }

        private static func isSetextUnderline(_ body: Substring) -> Bool {
            let trimmed = body.drop { $0 == " " || $0 == "\t" }.reversed().drop { $0 == " " || $0 == "\t" }
            guard let first = trimmed.first, first == "=" || first == "-" else { return false }
            return trimmed.allSatisfy { $0 == first }
        }

        private static func isFence(_ body: Substring) -> (marker: Character, length: Int)? {
            guard let first = body.first, first == "`" || first == "~" else { return nil }
            let run = body.prefix { $0 == first }
            guard run.count >= 3 else { return nil }
            // A backtick fence's info string may not contain backticks.
            if first == "`", body[run.endIndex...].contains("`") { return nil }
            return (first, run.count)
        }

        private static func isClosingFence(_ body: Substring, _ fence: (marker: Character, length: Int, depth: Int)) -> Bool {
            let run = body.prefix { $0 == fence.marker }
            guard run.count >= fence.length else { return false }
            return body[run.endIndex...].allSatisfy { $0 == " " || $0 == "\t" }
        }

        private static func isSpaceOrEnd(_ rest: Substring) -> Bool {
            guard let next = rest.first else { return true }
            return next == " " || next == "\t"
        }
    }
}
