(function () {
    const params = new URLSearchParams(window.location.search);
    const key = params.get('clearDraft');
    if (!key) return;

    try { localStorage.removeItem(key); } catch (_) {
        // ignore
    }

    params.delete('clearDraft');
    const query = params.toString();
    const newUrl = window.location.pathname + (query ? `?${query}` : '') + window.location.hash;
    history.replaceState(null, '', newUrl);
})();
