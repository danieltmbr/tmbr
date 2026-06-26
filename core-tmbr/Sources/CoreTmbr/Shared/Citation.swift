/// A single collected citation, ready to render as a numbered reference.
///
/// Produced by ``CitationCollector`` as markdown is walked. Both the web formatter and the
/// native `MarkdownView` operate on the same `Citation` values so numbering and anchor names
/// are identical on every platform.
public struct Citation: Codable, Sendable {

    /// 1-based sequential number assigned at collection time.
    public let number: Int

    /// Stable fragment anchor, e.g. `"reference-1"`. Used as the `id` on the reference block
    /// and as the fragment of the link on the superscript marker.
    public let anchorID: String

    /// The citation content as raw markdown. May contain inline formatting or links
    /// (e.g. `Andy Puddicombe, [Headspace](https://headspace.com)`). Each platform
    /// re-parses it with its own renderer so rich content is preserved.
    public let content: String

    /// Optional category drawn from the `cite:` attribute value (`podcast`, `song`, `album`,
    /// `book`, …). Carried through for future icon/label rendering; not yet rendered.
    public let kind: String?
}

public extension Citation {
    /// Canonical anchor identifier for a given citation number.
    /// Single source of truth — used by both web and native to ensure marker links and
    /// reference block IDs agree.
    static func anchorID(forNumber number: Int) -> String {
        "reference-\(number)"
    }
}

// MARK: - CitationCollector

/// Accumulates citations in document order and assigns sequential 1-based numbers.
///
/// Usage:
/// ```swift
/// var collector = CitationCollector()
/// let citation = collector.append(content: "Andy Puddicombe, Headspace", kind: "podcast")
/// // citation.number == 1, citation.anchorID == "reference-1"
/// let references = collector.references  // [citation]
/// ```
///
/// The collector owns the numbering policy. Callers walk the document (AST or attributed runs)
/// and call ``append(content:kind:)`` for each `cite`-attributed span in document order.
public struct CitationCollector: Sendable {

    private var items: [Citation] = []

    public init() {}

    /// Records a new citation and returns it with its assigned number and anchor.
    @discardableResult
    public mutating func append(content: String, kind: String?) -> Citation {
        let number = items.count + 1
        let citation = Citation(
            number: number,
            anchorID: Citation.anchorID(forNumber: number),
            content: content,
            kind: kind
        )
        items.append(citation)
        return citation
    }

    /// All collected citations in document order.
    public var references: [Citation] { items }

    /// `true` when no citations have been collected.
    public var isEmpty: Bool { items.isEmpty }
}

// MARK: - CitationPlacement

/// Where citations are rendered relative to the prose that cites them.
///
/// Injected via `@Environment` on native (see `MarkdownEnvironment`) or as a formatter
/// option on web, so the same markdown source can render two ways without modification.
public enum CitationPlacement: String, Codable, Sendable, CaseIterable {

    /// Citations are extracted from their inline position and gathered into a numbered
    /// references section at the end of the document. A superscript marker is left in place.
    /// This is the default and matches the visual convention of academic footnotes.
    case endOfDocument

    /// Citations are left where they appear and styled as an inline attribution
    /// (e.g. "— Andy Puddicombe, *Headspace*"), with no separate references section.
    /// Useful when the citation is a short attribution line that reads naturally in context.
    case inline
}
