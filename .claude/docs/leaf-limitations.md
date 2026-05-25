# Leaf Limitations

Evidence for replacing Leaf as the templating engine.

---

## 1. No conditional logic on collection state

**Where it hit:** `ComposePopupViewModel.directURL`

The compose button on list pages should navigate directly when there is only one action, and open a popup panel when there are multiple. This is a pure rendering concern — the view model should just describe *what* to render, not *how*.

Leaf cannot branch on array counts (`sections.flatMap(\.items).count == 1`) or any non-trivial expression inside `#if`. The only way to make the template work was to pre-compute a `directURL: String?` sentinel on the model itself and encode the rendering intent there. This pollutes the model with presentation logic and forces every consumer to handle a state space that should never exist (both `directURL` and `sections` present simultaneously).

The clean Swift solution is an enum with associated values:
```swift
enum ComposeViewModel {
    case direct(url: String)
    case panel([ComposeSectionViewModel])
}
```
But Leaf sees serialised JSON, not Swift types — so `#if(compose.url):` and `#if(compose.sections):` are indistinguishable from checking any other optional field. The enum eliminates the bad state in Swift but the template branch remains the same.

---

## 2. Single-level `#extend` / no script injection from partials

**Where it hit:** Embedded child views that need their own `<script>` tags.

Leaf's inheritance model allows a template to `#export` a named block (e.g. `scripts`) which a parent layout `#import`s. This works for one level. However, if a child partial is included inside a page that *already* exports `scripts`, the partial cannot also contribute to that block.

Concretely: a reusable component (e.g. an interactive widget) that needs its own JS cannot declare `#export("scripts")` inside itself, because the enclosing page template owns that export. The partial's export is silently ignored. The workaround is to inline the script in the partial (breaking separation of concerns) or require every parent page to manually include the partial's script dependencies (breaking encapsulation).

A component-oriented system (React, Vue, Swift UI-style) solves this naturally — each component declares its own dependencies and they are deduplicated at render time. Leaf has no equivalent.
