# Templates and Views

## HTML & CSS Rules

- Never use `<div>` when a semantic element exists — use `<article>`, `<section>`, `<nav>`, `<aside>`, `<main>`, `<footer>`, `<form>`, `<h1>`–`<h6>`
- Target tags in CSS, not classes — e.g. `article`, `section > ul`
- Only add classes when the same tag needs different visual variants that context can't distinguish
- Use flexbox/grid for all layout
- Use `<a>` links for navigation — no JS history manipulation

## Leaf Templates

Extend `Shared/page.leaf` with named slots:

```leaf
#extend("Shared/page")
#export("main") { ... }
```

## When Creating Pages

Use `Template<Model>` for compile-time safety:

```swift
Page(template: .postEditor, parser: { req in /* → ViewModel */ })
```

## When Handling Errors

- Per-page: `page.recover(handler)`
- Per-route-group: wrap with `RecoverMiddleware`

## Before Complex Frontend Work

Read `/.claude/docs/frontend.md` for detailed semantic element guidance and template examples.
