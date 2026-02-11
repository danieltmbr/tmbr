# Templates and Views

## HTML & CSS Rules

No CSS frameworks. No older-browser polyfills. Modern CSS/HTML only.

- **Never use `<div>` when a semantic element exists** — `<article>`, `<section>`, `<nav>`, `<aside>`, `<main>`, `<footer>`, `<form>`, `<h1>`–`<h6>`, etc.
- **CSS targets tags, not classes** — e.g. `article`, `section > ul`. Only add a class when the same tag genuinely needs different visual variants that context can't distinguish.
- **Flexbox/grid for all layout.**
- **Navigation = `<a>` links.** No JS history manipulation. Dynamic content loading is fine only when it doesn't change the navigable URL state.

## Leaf Templates

Templates compose from shared fragments. `Shared/page.leaf` is the base layout with named slots (`main`, `toolbar`, `styles`, `scripts`).

Page templates extend via:
```leaf
#extend("Shared/page")
#export("main") { ... }
```

## Template<Model> Pattern

`Template<Model>` binds a Leaf template name to a ViewModel type for compile-time safety.

```swift
Page(template: .postEditor, parser: { req in /* → ViewModel */ })
```

## Error Recovery

Two levels:
- **Per-page**: `page.recover(handler)` for page-specific errors
- **Per-route-group**: `RecoverMiddleware` wrapping a route collection

```swift
routes.grouped(RecoverMiddleware()).register(collection: PostsWebController())
```

## Static Assets

- `Public/Styles/` — CSS files
- `Public/Scripts/` — JavaScript files
- `Public/Assets/` — Images and other assets
