class DraftClearController {
    constructor({ paramName = 'clearDraft' } = {}) {
        this.paramName = paramName;
    }

    init() {
        const params = new URLSearchParams(window.location.search);
        const key = params.get(this.paramName);
        if (!key) return;

        try { localStorage.removeItem(key); } catch (_) {
            // ignore
        }

        params.delete(this.paramName);
        const query = params.toString();
        const newUrl = window.location.pathname + (query ? `?${query}` : '') + window.location.hash;
        history.replaceState(null, '', newUrl);
    }

    destroy() {}
}

document.addEventListener('DOMContentLoaded', () => {
    new DraftClearController().init();
});
