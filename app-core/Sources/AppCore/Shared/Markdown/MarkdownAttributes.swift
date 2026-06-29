import Foundation

// MARK: - Legacy inline-attribute keys (web hand-authored markup)

/// Maps the web's `htmltag:` inline-attribute key to Foundation's custom attribute system.
/// Used by hand-authored legacy footnote markup: `^[[1](#ref-1)](class: reference-id, htmltag: sup)`.
/// Replaced by `CiteAttribute` for new posts; retained for backward compatibility during migration.
enum HTMLTagAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    typealias Value = String
    static let name = "htmltag"
}

/// Maps the web's `class:` inline-attribute key. Part of the legacy footnote markup.
enum CSSClassAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    typealias Value = String
    static let name = "class"
}

/// Maps the web's `id:` inline-attribute key — marks scroll-to targets in legacy footnote markup.
/// Syntax: `^[1: Author, Work](class: reference, id: reference-1)`.
enum AnchorIDAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    typealias Value = String
    static let name = "id"
}

// MARK: - Citation attribute keys (new syntax)

/// Marks a span as a standalone citation to be numbered and relocated.
/// Syntax: `^[Author, [Work](url)](cite: podcast)`.
///
/// The **span text** is the citation content (rich markdown — links, emphasis — supported).
/// The **attribute value** is the optional category/kind (`podcast`/`song`/`album`/`book`/…).
/// Use `cite: source` as a generic default when no category applies.
enum CiteAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    typealias Value = String
    static let name = "cite"
}

/// Applied by the citation preprocess pass to replace a `cite`-marked span with its assigned
/// sequential number. The `MarkdownDecorator.footnote` factory reads this to render a
/// superscript marker. Never authored directly in markdown.
enum FootnoteMarkerAttribute: CodableAttributedStringKey {
    typealias Value = Int
    static let name = "footnoteMarker"
}

// MARK: - Attribute scope

extension AttributeScopes {
    /// Combined scope used when parsing markdown. Includes our custom keys AND the standard
    /// Foundation attributes (`presentationIntent`, `link`, `inlinePresentationIntent`, …) so
    /// that passing this scope to `AttributedString(markdown:including:)` preserves all
    /// standard Foundation markdown attributes alongside the custom web ones.
    struct TmbrAttributes: AttributeScope {
        // Citation (new syntax)
        let cite: CiteAttribute
        // Footnote marker — set programmatically by the preprocess pass, not decoded from markdown
        let footnoteMarker: FootnoteMarkerAttribute
        // Legacy web attributes (hand-authored markup; retained during migration)
        let htmlTag: HTMLTagAttribute
        let cssClass: CSSClassAttribute
        let anchorID: AnchorIDAttribute
        let foundation: AttributeScopes.FoundationAttributes
    }

    var tmbr: TmbrAttributes.Type { TmbrAttributes.self }
}
