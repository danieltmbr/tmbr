# Frontend Development

## HTML & CSS

No CSS frameworks. No older-browser polyfills. Modern CSS/HTML only.

### Semantic Elements

**Never use `<div>` when a semantic element exists:**

| Element | Use For |
|---------|---------|
| `<article>` | Self-contained content |
| `<section>` | Thematic grouping |
| `<nav>` | Navigation links |
| `<aside>` | Tangentially related content |
| `<main>` | Main content area |
| `<header>`, `<footer>` | Document/section headers and footers |
| `<form>` | User input |
| `<h1>`–`<h6>` | Headings |

### CSS Selectors

**Target tags, not classes** — e.g. `article`, `section > ul`, `nav a`.

Only add a class when the same tag genuinely needs different visual variants that context can't distinguish.

```css
/* Preferred */
article { ... }
article header { ... }
article > section { ... }

/* Only when necessary */
article.featured { ... }
```

### Layout

**Flexbox/grid for all layout.** No floats, no table-based layouts.

### Navigation

**Navigation = `<a>` links.** No JS history manipulation.

Dynamic content loading is fine only when it doesn't change the navigable URL state (e.g., pre-filling form fields from an API call).

## JavaScript

Vanilla JS only — no frameworks or build tools. Scripts live in `Public/Scripts/`.

### Controller Pattern

Split complex features into single-responsibility Controller classes. Each controller owns one concern (editor state, drag-and-drop, gallery, keyboard shortcuts, persistence).

```javascript
class EditorController {
    constructor({ form, titleInput, bodyTextArea }, { persistence }) {
        // Store DOM elements
        this.form = form;
        this.titleInput = titleInput;
        this.bodyTextArea = bodyTextArea;
        // Store injected dependencies
        this.persistence = persistence;
        // Bind event handlers in constructor
        this._onInput = this.onInput.bind(this);
        this._onSubmit = this.onSubmit.bind(this);
    }

    init() {
        this.titleInput.addEventListener('input', this._onInput);
        this.form.addEventListener('submit', this._onSubmit);
    }

    destroy() {
        this.titleInput.removeEventListener('input', this._onInput);
        this.form.removeEventListener('submit', this._onSubmit);
    }

    onInput(event) { /* ... */ }
    onSubmit(event) { /* ... */ }
}
```

### Conventions

- **Constructor signature**: DOM elements as first object, dependencies as second object
- **Lifecycle methods**: `init()` attaches listeners, `destroy()` removes them
- **Handler binding**: Bind handlers in constructor, store as `this._onEventName`
- **No static methods**: Even stateless operations should be instance methods on a controller, injected as a dependency — keeps everything testable and consistent

### Bootstrap Pattern

Initialize everything in `DOMContentLoaded`, wire controllers together:

```javascript
document.addEventListener('DOMContentLoaded', () => {
    // Get DOM elements
    const form = document.getElementById('post-form');
    const titleInput = document.getElementById('title');
    const bodyTextArea = document.getElementById('body');

    // Create dependencies
    const persistence = new PersistenceController({ /* ... */ });
    persistence.init();

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
        persistence.destroy();
    });
});
```

### Reference Implementation

See `Public/Scripts/post-editor.js` for a complete working example.

## Leaf Templates

Templates live in `Resources/Views/` and compose from shared fragments.

### Base Layout

`Shared/page.leaf` is the base layout with named slots: `main`, `toolbar`, `styles`, `scripts`.

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
#export("scripts") {
    <script src="/Scripts/article.js"></script>
}
```

### Template<Model> Pattern

`Template<Model>` binds a Leaf template name to a ViewModel type for compile-time safety.

```swift
Page(template: .postEditor, parser: { req in /* returns ViewModel */ })
```

### Error Recovery

Two levels:

**Per-page** — for page-specific error handling:
```swift
page.recover { error, request in
    // return fallback response
}
```

**Per-route-group** — wrap a route collection:
```swift
routes.grouped(RecoverMiddleware()).register(collection: PostsWebController())
```

## Static Assets

- `Public/Styles/` — CSS files
- `Public/Scripts/` — JavaScript files
- `Public/Assets/` — Images and other static assets
