import Foundation

// MARK: - Attribute keys

/// Maps the web's `htmltag:` inline-attribute key to Foundation's custom attribute system.
/// Syntax in markdown: `^[text](htmltag: sup, class: reference-id)`.
enum HTMLTagAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    typealias Value = String
    static let name = "htmltag"
}

/// Maps the web's `class:` inline-attribute key.
enum CSSClassAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    typealias Value = String
    static let name = "class"
}

/// Maps the web's `id:` inline-attribute key — marks scroll-to targets (footnote references).
/// Syntax: `^[1: Author, Work](class: reference, id: reference-1)`.
enum AnchorIDAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    typealias Value = String
    static let name = "id"
}

// MARK: - Attribute scope

extension AttributeScopes {
    /// Combined scope used when parsing markdown. Includes our custom keys AND the standard
    /// Foundation attributes (`presentationIntent`, `link`, `inlinePresentationIntent`, …) so
    /// that passing this scope to `AttributedString(markdown:including:)` preserves all
    /// standard Foundation markdown attributes alongside the custom web ones.
    struct TmbrAttributes: AttributeScope {
        let htmlTag: HTMLTagAttribute
        let cssClass: CSSClassAttribute
        let anchorID: AnchorIDAttribute
        let foundation: AttributeScopes.FoundationAttributes
    }

    var tmbr: TmbrAttributes.Type { TmbrAttributes.self }
}
