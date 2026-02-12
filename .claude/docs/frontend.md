# Frontend Development

## HTML & CSS Philosophy

No CSS frameworks. No older-browser polyfills. Modern CSS/HTML only.

### Semantic Elements

**Never use `<div>` when a semantic element exists:**
- `<article>` — Self-contained content
- `<section>` — Thematic grouping
- `<nav>` — Navigation links
- `<aside>` — Tangentially related content
- `<main>` — Main content area
- `<header>`, `<footer>` — Document/section headers and footers
- `<form>` — User input
- `<h1>`–`<h6>` — Headings

### CSS Targeting

**CSS targets tags, not classes** — e.g. `article`, `section > ul`.

Only add a class when the same tag genuinely needs different visual variants that context can't distinguish.

### Layout

**Flexbox/grid for all layout.** No floats, no table-based layouts.

### Navigation

**Navigation = `<a>` links.** No JS history manipulation.

Dynamic content loading is fine only when it doesn't change the navigable URL state (e.g. pre-filling form fields from an API call).

## JavaScript

Vanilla JS only — no frameworks or build tools. Scripts live in `Public/Scripts/`.

### Controller Pattern

Complex features are split into single-responsibility Controller classes. Each controller owns one concern (editor state, drag-and-drop, gallery, keyboard shortcuts, persistence).

```javascript
class EditorController {
    constructor({ form, titleInput, bodyTextArea }, { persistence }) {
        // Store DOM elements
        this.form = form;
        this.titleInput = titleInput;
        // Store injected dependencies
        this.persistence = persistence;
        // Bind event handlers in constructor
        this._onInput = this.onInput.bind(this);
    }

    init() {
        this.titleInput.addEventListener('input', this._onInput);
    }

    destroy() {
        this.titleInput.removeEventListener('input', this._onInput);
    }
}
```

### Key Conventions

- **Constructor signature**: DOM elements as first object, dependencies as second object
- **Lifecycle methods**: `init()` attaches listeners, `destroy()` removes them
- **Handler binding**: Bind handlers in constructor, store as `this._onEventName`
- **No static methods**: Even stateless operations should be instance methods on a controller, injected as a dependency — keeps everything testable and consistent

### Bootstrap Example

Initialize everything in `DOMContentLoaded`, wire controllers together:

```javascript
document.addEventListener('DOMContentLoaded', () => {
    // Get DOM elements
    const form = document.getElementById('post-form');
    const titleInput = document.getElementById('title');
    const bodyTextArea = document.getElementById('body');

    // Create dependencies
    const persistence = new PersistenceController();

    // Create and initialize main controller
    const editor = new EditorController(
        { form, titleInput, bodyTextArea },
        { persistence }
    );
    editor.init();

    // Create supporting controllers with callbacks
    const shortcuts = new ShortcutsController({
        onSave: () => editor.save(),
        onCancel: () => editor.discard()
    });
    shortcuts.init();

    // Cleanup on page unload if needed
    window.addEventListener('beforeunload', () => {
        editor.destroy();
        shortcuts.destroy();
    });
});
```

### Reference Implementation

See `Public/Scripts/post-editor.js` for a complete working example.

## Leaf Templates

Templates compose from shared fragments. `Shared/page.leaf` is the base layout with named slots (`main`, `toolbar`, `styles`, `scripts`).

Page templates extend via:
```leaf
#extend("Shared/page")
#export("main") {
    <article>
        <h1>#(title)</h1>
        #(content)
    </article>
}
#export("styles") {
    <link rel="stylesheet" href="/Styles/article.css">
}
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
