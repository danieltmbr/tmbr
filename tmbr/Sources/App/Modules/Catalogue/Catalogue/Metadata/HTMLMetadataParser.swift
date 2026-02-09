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
    
    private func metaPattern(key: String) -> String {
        "<meta\\b[^>]*\\b\(key)=[\"']([^\"']+)[\"'][^>]*\\bcontent=[\"']([^\"']*)[\"'][^>]*>"
    }
    
    private func metaPatternContentFirst(key: String) -> String {
        "<meta\\b[^>]*\\bcontent=[\"']([^\"']*)[\"'][^>]*\\b\(key)=[\"']([^\"']+)[\"'][^>]*>"
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
        collectMatches(in: text, regex: regex1, keyIndex: 1, valueIndex: 2, into: &results)
        collectMatches(in: text, regex: regex2, keyIndex: 2, valueIndex: 1, into: &results)
        return results
    }

    private func collectMatches(
        in text: String,
        regex: NSRegularExpression,
        keyIndex: Int,
        valueIndex: Int,
        into results: inout [String: String]
    ) {
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        regex.enumerateMatches(in: text, options: [], range: nsRange) { m, _, _ in
            guard let m = m,
                  keyIndex < m.numberOfRanges,
                  valueIndex < m.numberOfRanges,
                  let keyRange = Range(m.range(at: keyIndex), in: text),
                  let valueRange = Range(m.range(at: valueIndex), in: text) else { return }

            let key = text[keyRange].trimmingCharacters(in: .whitespacesAndNewlines)
            let decodedValue = decodeEntities(String(text[valueRange]).trimmingCharacters(in: .whitespacesAndNewlines))
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
