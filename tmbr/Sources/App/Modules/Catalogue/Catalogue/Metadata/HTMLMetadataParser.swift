import Foundation

struct HTMLMetadataParser {

    func parse(html: String) -> [String: String] {
        let head = head(from: html) ?? html
        return match(in: head, key: "property")
            .merging(
                match(in: head, key: "name"),
                uniquingKeysWith: { current, _ in current }
            )
    }

    // MARK: - Helpers

    // Patterns handle quoted attributes properly - matching the same quote type that opened the value
    // This allows apostrophes in double-quoted values and vice versa

    private func metaPattern(key: String) -> String {
        // property="value" content="value" OR property='value' content='value'
        "<meta\\b[^>]*\\b\(key)=(?:\"([^\"]+)\"|'([^']+)')[^>]*\\bcontent=(?:\"([^\"]*)\"|'([^']*)')[^>]*>"
    }

    private func metaPatternContentFirst(key: String) -> String {
        // content="value" property="value" OR content='value' property='value'
        "<meta\\b[^>]*\\bcontent=(?:\"([^\"]*)\"|'([^']*)')[^>]*\\b\(key)=(?:\"([^\"]+)\"|'([^']+)')[^>]*>"
    }
    
    private let options: NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]
    
    private func head(from text: String) -> String? {
        guard let headOpen = text.range(of: "<head", options: .caseInsensitive),
              let gt = text[headOpen.lowerBound...].firstIndex(of: ">"),
              let headClose = text.range(of: "</head>", options: .caseInsensitive, range: text.index(after: gt)..<text.endIndex) else {
            return nil
        }
        return String(text[headOpen.lowerBound..<headClose.upperBound])
    }
    
    private func regex(pattern: String) -> NSRegularExpression {
        (try? NSRegularExpression(pattern: pattern, options: options)) ?? NSRegularExpression()
    }

    private func match(
        in text: String,
        key: String
    ) -> [String: String] {
        let regex1 = regex(pattern: metaPattern(key: key))
        let regex2 = regex(pattern: metaPatternContentFirst(key: key))
        var results: [String: String] = [:]
        // metaPattern: groups 1,2 are key (double/single quoted), groups 3,4 are value
        collectMatches(in: text, regex: regex1, keyIndices: [1, 2], valueIndices: [3, 4], into: &results)
        // metaPatternContentFirst: groups 1,2 are value, groups 3,4 are key
        collectMatches(in: text, regex: regex2, keyIndices: [3, 4], valueIndices: [1, 2], into: &results)
        return results
    }

    private func collectMatches(
        in text: String,
        regex: NSRegularExpression,
        keyIndices: [Int],
        valueIndices: [Int],
        into results: inout [String: String]
    ) {
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        regex.enumerateMatches(in: text, options: [], range: nsRange) { m, _, _ in
            guard let m = m else { return }

            // Find which key group matched (alternation means only one will)
            let keyString = keyIndices.lazy
                .compactMap { index -> String? in
                    guard index < m.numberOfRanges,
                          m.range(at: index).location != NSNotFound,
                          let range = Range(m.range(at: index), in: text) else { return nil }
                    return String(text[range])
                }
                .first

            // Find which value group matched
            let valueString = valueIndices.lazy
                .compactMap { index -> String? in
                    guard index < m.numberOfRanges,
                          m.range(at: index).location != NSNotFound,
                          let range = Range(m.range(at: index), in: text) else { return nil }
                    return String(text[range])
                }
                .first

            guard let key = keyString?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let value = valueString else { return }

            let decodedValue = decodeEntities(value.trimmingCharacters(in: .whitespacesAndNewlines))
            results[key] = decodedValue
        }
    }

    private func firstMatch(
        in text: String,
        regex: NSRegularExpression,
        group: Int
    ) -> String? {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let m = regex.firstMatch(in: text, options: [], range: range) else { return nil }
        let g = m.range(at: group)
        guard g.location != NSNotFound, let r = Range(g, in: text) else { return nil }
        return String(text[r])
    }

    // Minimal HTML entity decoding for common cases
    private func decodeEntities(_ s: String) -> String {
        var t = s
        let entities: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#39;": "'",
            "&apos;": "'",
            "&nbsp;": " "
        ]
        for (k, v) in entities {
            if t.contains(k) { t = t.replacingOccurrences(of: k, with: v) }
        }
        // numeric entities
        let numericPattern = "&#(\\d+);"
        if let regex = try? NSRegularExpression(pattern: numericPattern, options: []) {
            let range = NSRange(t.startIndex..<t.endIndex, in: t)
            var out = t
            let matches = regex.matches(in: t, options: [], range: range).reversed()
            for m in matches {
                if m.numberOfRanges >= 2,
                   let rr = Range(m.range(at: 0), in: out),
                   let gr = Range(m.range(at: 1), in: out),
                   let code = Int(out[gr]),
                   let scalar = UnicodeScalar(code) {
                    out.replaceSubrange(rr, with: String(scalar))
                }
            }
            t = out
        }
        return t
    }
}
