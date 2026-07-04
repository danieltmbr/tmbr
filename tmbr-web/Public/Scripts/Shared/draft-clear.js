class DraftClearController {
    constructor({ paramName = 'clearDraft' } = {}) {
        this.paramName = paramName;
    }

    clearIfRequested() {
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
}

document.addEventListener('DOMContentLoaded', () => {
    new DraftClearController().clearIfRequested();
});
