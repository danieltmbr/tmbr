class ShortcutsController {
    static login = {
        key: 'l',
        action: () => {
            const redirect = encodeURIComponent(window.location.pathname + window.location.search);
            window.location.assign('/signin?redirectReturn=' + redirect);
        }
    };

    static edit = {
        key: 'e',
        action: () => window.location.assign(window.location.href + '/edit')
    };

    static preview = (action) => ({ key: 'p', meta: true, alt: true, action });

    static gallery = (action) => ({ key: 'g', meta: true, alt: true, action });

    constructor(handlers) {
        this._handlers = {};
        for (const h of handlers) {
            this._handlers[h.key.toLowerCase()] = h;
        }
        this._onKeyDown = this._handleKeyDown.bind(this);
    }

    init() {
        document.addEventListener('keydown', this._onKeyDown);
    }

    destroy() {
        document.removeEventListener('keydown', this._onKeyDown);
    }

    _handleKeyDown(event) {
        const tag = event.target.tagName;
        if (tag === 'INPUT' || tag === 'TEXTAREA' || event.target.isContentEditable) return;
        const h = this._handlers[event.key.toLowerCase()];
        if (!h) return;
        const isMac = navigator.platform.toUpperCase().includes('MAC');
        const cmdOrCtrl = isMac ? event.metaKey : event.ctrlKey;
        if (h.meta || h.alt) {
            if ((h.meta ?? false) !== cmdOrCtrl) return;
            if ((h.alt ?? false) !== event.altKey) return;
            if (event.shiftKey) return;
        } else {
            if (event.metaKey || event.ctrlKey || event.altKey || event.shiftKey) return;
        }
        event.preventDefault();
        h.action(event);
    }
}
