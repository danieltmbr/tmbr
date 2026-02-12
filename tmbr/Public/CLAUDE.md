# Public Assets

## JavaScript Rules

- Vanilla JS only — no frameworks or build tools
- Split complex features into single-responsibility Controller classes
- Constructor signature: DOM elements as first object, dependencies as second
- Use `init()` to attach listeners, `destroy()` to remove them
- Bind handlers in constructor, store as `this._onEventName`
- No static methods — inject stateless operations as dependencies
- Initialize in `DOMContentLoaded`, wire controllers together

## Controller Template

```javascript
class EditorController {
    constructor({ form, titleInput }, { persistence }) {
        this.form = form;
        this.titleInput = titleInput;
        this.persistence = persistence;
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

Reference: `Public/Scripts/post-editor.js`

## CSS Rules

- No CSS frameworks — modern CSS only
- Target tags in CSS, not classes — e.g. `article`, `section > ul`
- Only add classes when the same tag needs different visual variants that context can't distinguish
- Use flexbox/grid for all layout

## Before Complex Frontend Work

Read `/.claude/docs/frontend.md` for full bootstrap example, semantic element guidance, and Leaf template patterns.
