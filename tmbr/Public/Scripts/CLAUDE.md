# JavaScript

Vanilla JS only — no frameworks or build tools.

## Controller Pattern

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

## Conventions

- **Constructor signature**: DOM elements as first object, dependencies as second object
- **Lifecycle methods**: `init()` attaches listeners, `destroy()` removes them
- **Handler binding**: Bind handlers in constructor, store as `this._onEventName`
- **No static methods**: Even stateless operations should be instance methods on a controller, injected as a dependency — keeps everything testable and consistent

## Bootstrap

Initialize everything in `DOMContentLoaded`, wire controllers together:

```javascript
document.addEventListener('DOMContentLoaded', () => {
    const persistence = new PersistenceController();
    const editor = new EditorController({ form, titleInput }, { persistence });
    editor.init();

    const shortcuts = new ShortcutsController({
        onSave: () => editor.save()
    });
    shortcuts.init();
});
```

## Reference Implementation

See `Public/Scripts/post-editor.js` for a complete example.
