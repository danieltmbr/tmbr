document.addEventListener('DOMContentLoaded', () => {
    const urlInput = document.getElementById('editor-url');
    const titleInput = document.getElementById('editor-title');
    const subtitleInput = document.getElementById('editor-subtitle');
    const artworkImage = document.getElementById('artwork-image');
    const artworkPlaceholder = document.getElementById('artwork-placeholder');
    const artworkClear = document.getElementById('artwork-clear');
    const artworkSourceInput = document.getElementById('editor-artwork-source-url');
    const statusEl = document.getElementById('autofill-status');

    if (!urlInput) return;

    urlInput.addEventListener('blur', onURLBlur);
    urlInput.addEventListener('change', onURLBlur);
    artworkClear?.addEventListener('click', clearArtwork);

    async function onURLBlur() {
        const url = urlInput.value.trim();
        if (!url) return;

        setStatus('Fetching metadata…');
        try {
            const res = await fetch(`/catalogue/new/metadata?url=${encodeURIComponent(url)}`);
            if (!res.ok) { setStatus(''); return; }
            const data = await res.json();
            autofill(data);
            setStatus('');
        } catch {
            setStatus('');
        }
    }

    function autofill(data) {
        if (data.title && !titleInput.value.trim()) {
            titleInput.value = data.title;
        }
        if (data.subtitle && !subtitleInput.value.trim()) {
            subtitleInput.value = data.subtitle;
        }
        if (data.artworkURL) {
            setArtwork(data.artworkURL);
        }
    }

    function setArtwork(url) {
        artworkImage.src = url;
        artworkSourceInput.value = url;
        artworkPlaceholder.classList.remove('empty');
    }

    function clearArtwork() {
        artworkImage.src = '';
        artworkSourceInput.value = '';
        artworkPlaceholder.classList.add('empty');
    }

    function setStatus(msg) {
        if (!statusEl) return;
        statusEl.textContent = msg;
        statusEl.hidden = !msg;
    }
});
