document.addEventListener('DOMContentLoaded', () => {
    const urlInput = document.getElementById('music-editor-url');
    const typeSelector = document.getElementById('music-type-selector');
    const fieldsContainer = document.getElementById('music-editor-fields');
    const statusEl = document.getElementById('music-autofill-status');
    const form = document.getElementById('music-editor-form');

    if (!urlInput || !form) return;

    // Type → target form action
    const typeActions = {
        song: '/songs/new',
        album: '/albums/new',
        playlist: '/playlists/new',
    };

    let debounceTimer = null;
    let currentType = null;

    function setStatus(msg, hidden = false) {
        if (!statusEl) return;
        statusEl.textContent = msg;
        statusEl.hidden = hidden;
    }

    function applyMetadata(data) {
        currentType = data.musicType;
        if (!currentType || currentType === 'unknown') {
            typeSelector.hidden = false;
            fieldsContainer.hidden = true;
            setStatus('Could not detect music type — please select manually.', false);
            return;
        }
        typeSelector.hidden = true;
        fieldsContainer.hidden = false;
        setStatus('');

        // Redirect to the type-specific editor pre-filled via query string
        const params = new URLSearchParams();
        if (data.title) params.set('title', data.title);
        if (data.artist) params.set('artist', data.artist);
        if (data.description) params.set('description', data.description);
        if (data.artwork) params.set('artworkURL', data.artwork);
        if (data.releaseDate) params.set('releaseDate', data.releaseDate);
        if (data.genre) params.set('genre', data.genre);
        if (Array.isArray(data.tracks) && data.tracks.length > 0) {
            params.set('tracklistJSON', JSON.stringify(data.tracks));
        }
        params.set('url', urlInput.value);

        const action = typeActions[currentType];
        if (action) {
            window.location.href = `${action}?${params}`;
        }
    }

    async function fetchMetadata(url) {
        try {
            setStatus('Detecting…', false);
            const res = await fetch(`/music/metadata?url=${encodeURIComponent(url)}`);
            if (!res.ok) throw new Error(`Status ${res.status}`);
            const data = await res.json();
            applyMetadata(data);
        } catch (err) {
            console.error(err);
            setStatus('Could not fetch metadata. Please paste a valid Apple Music link.', false);
            typeSelector.hidden = false;
        }
    }

    urlInput.addEventListener('input', () => {
        clearTimeout(debounceTimer);
        const value = urlInput.value.trim();
        if (!value) {
            typeSelector.hidden = true;
            fieldsContainer.hidden = true;
            setStatus('', true);
            return;
        }
        debounceTimer = setTimeout(() => fetchMetadata(value), 500);
    });

    // Manual type selection → redirect to type-specific editor with URL prefilled
    typeSelector.addEventListener('change', (e) => {
        const type = e.target.value;
        const action = typeActions[type];
        if (action && urlInput.value) {
            window.location.href = `${action}?url=${encodeURIComponent(urlInput.value)}`;
        }
    });
});
