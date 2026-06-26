import SwiftUI

/// A composable unit of Markdown run styling.
///
/// A `MarkdownDecorator` receives a mutable `AttributedSubstring` corresponding to one run
/// of an `AttributedString` and applies styling — fonts, colors, or any SwiftUI/UIKit/AppKit
/// attributed string attributes. Multiple decorators compose into one via ``init(_:)``;
/// they run in array order, so later decorators can override earlier ones.
///
/// Create specific decorators with the static factory properties (`.heading`, `.link`, …)
/// and assemble a custom set with the composing initializer:
///
/// ```swift
/// let myDecorator = MarkdownDecorator([
///     .heading, .inlineCode,
///     MarkdownDecorator { run in
///         if run.link != nil { run.swiftUI.foregroundColor = .purple }
///     }
/// ])
/// ```
///
/// Inject into a view hierarchy via the `\.markdownDecorator` environment key, or the
/// `.markdownDecorator(_:)` view modifier, to override the `\.standard` default.
///
/// - Note: The mutable unit is `AttributedSubstring` (`content[range]`), not
///   `AttributedString.Runs.Run`. A `Run` is read-only — it exposes attribute values for
///   inspection but has no mutation API. `AttributedSubstring` is both readable and writable,
///   so a single handle both reads intents and applies styling back to the string in place.
///
/// - Note: Decorators run *before* `presentationIntent` is stripped from each block, so the
///   `.heading` factory can read the header level from the intent and set the font accordingly.
public struct MarkdownDecorator: Sendable {

    private let decorate: @Sendable (inout AttributedSubstring) -> Void

    public init(_ decorate: @escaping @Sendable (inout AttributedSubstring) -> Void) {
        self.decorate = decorate
    }

    public func callAsFunction(_ run: inout AttributedSubstring) {
        decorate(&run)
    }
}

// MARK: - Composition

public extension MarkdownDecorator {
    /// Composes multiple decorators into one, applying them in array order.
    /// Later decorators override earlier ones where attributes overlap.
    init(_ decorators: [MarkdownDecorator]) {
        self.init { run in
            for decorator in decorators { decorator(&run) }
        }
    }
}

// MARK: - Standard factories

public extension MarkdownDecorator {

    /// Sets the heading font from the run's `presentationIntent` header level.
    /// Must run before `presentationIntent` is stripped.
    static let heading = MarkdownDecorator { run in
        guard let intent = run.presentationIntent else { return }
        for component in intent.components {
            if case .header(let level) = component.kind {
                run.swiftUI.font = headingFont(level)
                return
            }
        }
    }

    /// Applies the accent color to link runs. Tap routing for internal `/posts/<id>` links
    /// is out of scope for this pass — links open via the standard `openURL` environment
    /// action, which PostReaderView intercepts for `#fragment` anchor jumps.
    static let link = MarkdownDecorator { run in
        guard run.link != nil else { return }
        run.swiftUI.foregroundColor = .accentColor
    }

    /// Applies a monospaced font to inline code spans.
    static let inlineCode = MarkdownDecorator { run in
        guard let intent = run.inlinePresentationIntent, intent.contains(.code) else { return }
        run.swiftUI.font = .system(.body, design: .monospaced)
    }

    /// Styles citation markers produced by the `MarkdownFootnotes` preprocess pass.
    ///
    /// A marker run carries `FootnoteMarkerAttribute` (the assigned citation number) and a `link`
    /// to the reference anchor. This decorator renders it as a superscript-style label (smaller
    /// font, raised baseline) with the accent color. The `link` is left intact so tapping the
    /// marker triggers the fragment-URL intercept in `PostReaderView`.
    ///
    /// - Note: SwiftUI has no true superscript attribute. We approximate with `.caption` size
    ///   and a UIKit/AppKit baseline offset. The marker renders smaller; vertical raise depends
    ///   on platform.
    static let footnote = MarkdownDecorator { run in
        guard run.runs.first?[FootnoteMarkerAttribute.self] != nil else { return }
        run.swiftUI.font = .caption
        run.swiftUI.foregroundColor = .accentColor
#if canImport(UIKit)
        run.uiKit.baselineOffset = 6
#elseif canImport(AppKit)
        run.appKit.baselineOffset = 4
#endif
    }

    /// Styles inline citations left in place when `CitationPlacement.inline` is active.
    /// Renders as a secondary-color attribution (e.g. "— Andy Puddicombe, *Headspace*").
    static let citation = MarkdownDecorator { run in
        guard run.runs.first?[CiteAttribute.self] != nil else { return }
        run.swiftUI.foregroundColor = .secondary
    }

    /// Legacy: handles the hand-authored `htmltag: sup` footnote markup that exists in
    /// posts written before the `cite:` syntax. Retained during migration.
    /// Will be removed once all post bodies have been converted.
    static let legacyFootnote = MarkdownDecorator { run in
        guard run.runs.first?[HTMLTagAttribute.self] == "sup" else { return }
        run.swiftUI.font = .caption
        run.swiftUI.foregroundColor = .accentColor
#if canImport(UIKit)
        run.uiKit.baselineOffset = 6
#elseif canImport(AppKit)
        run.appKit.baselineOffset = 4
#endif
    }

    /// Override point for bold runs. `Text` renders bold natively via `inlinePresentationIntent`;
    /// this factory exists so callers can override bold styling without replacing the entire set.
    static let bold = MarkdownDecorator { _ in }

    /// Override point for italic runs (same rationale as `.bold`).
    static let italic = MarkdownDecorator { _ in }

    /// Override point for strikethrough runs (same rationale as `.bold`).
    static let strikethrough = MarkdownDecorator { _ in }

    /// The standard decorator set. Applied by default to all `MarkdownView` instances.
    /// Includes both the new `cite`-based footnote styling and legacy `htmltag: sup` support
    /// during the post-body migration window.
    static let standard = MarkdownDecorator([
        .heading, .link, .inlineCode, .footnote, .citation, .legacyFootnote
    ])
}

// MARK: - Private helpers

private func headingFont(_ level: Int) -> Font {
    switch level {
    case 1: return .title.bold()
    case 2: return .title2.bold()
    case 3: return .title3.bold()
    default: return .headline
    }
}
