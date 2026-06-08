document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('editor-form');
    if (!form) return;

    const idInput            = document.getElementById('editor-id');
    const titleInput         = document.getElementById('editor-title');
    const descriptionInput   = document.getElementById('editor-description');
    const tracklistJsonInput = document.getElementById('editor-tracklist-json');
    const statusEl           = document.getElementById('autofill-status');

    const resourcesSection = document.getElementById('resources-section');
    const detailsSection   = document.getElementById('details-section');
    const notesSection     = document.getElementById('notes-section');
    const gallery          = document.getElementById('gallery');
    const gallerySection   = document.getElementById('gallery-section');
    const galleryStatus    = document.getElementById('gallery-status');
    const galleryTitle     = document.getElementById('gallery-title');
    const notesGalleryOpen = document.getElementById('notes-gallery-open');
    const galleryClose     = document.getElementById('gallery-close');

    const persistence = new PersistenceController();
    const uploads     = new UploadsController();
    const metadata    = new MetadataController({ endpoint: '/playlists/metadata' });

    const itemID     = idInput?.value || '';
    const storageKey = itemID ? `editor:playlist:${itemID}` : 'editor:playlist:new';

    const artwork = new ArtworkController({
        hiddenInput:      document.getElementById('editor-artwork-id'),
        externalUrlInput: document.getElementById('editor-artwork-source-url'),
        placeholder:      document.getElementById('artwork-placeholder'),
        imageEl:          document.getElementById('artwork-image'),
        clearButton:      document.getElementById('artwork-clear'),
    }, {
        onChange:      () => saveDraft(),
        onOpenGallery: () => imagePicker.open('image'),
    });
    artwork.init();

    const notes = new NotesController(
        { section: notesSection },
        { onInput: () => saveDraft(), onAccessChange: () => saveDraft() }
    );
    notes.init();

    // No lookup for playlists
    const duplicateAlert = new DuplicateAlertController(
        { containerEl: document.getElementById('duplicate-container'), linkSelector: '#duplicate-playlist-link' },
        { onNavigate: () => persistence.clear(storageKey) }
    );
    duplicateAlert.init();

    const resourceInputs = new ResourceInputsController(
        { section: resourcesSection },
        { onUrlChange: (url) => autofill.fetchAndApply(url), onInput: () => saveDraft() }
    );
    resourceInputs.init();

    function getState() {
        return {
            title:              titleInput?.value || '',
            description:        descriptionInput?.value || '',
            notes:              notes.getNotes(),
            resourceURLs:       resourceInputs.getValues(),
            artworkId:          artwork.getArtworkId(),
            artworkThumbnailUrl: artwork.getThumbnailUrl(),
            artworkExternalURL: artwork.getExternalURL(),
        };
    }

    function setState(state) {
        if (!state || typeof state !== 'object') return;
        if (typeof state.title === 'string' && !titleInput.value) titleInput.value = state.title;
        if (typeof state.description === 'string' && !descriptionInput.value) descriptionInput.value = state.description;
        if (Array.isArray(state.notes)) notes.setNotes(state.notes, true);
        if (Array.isArray(state.resourceURLs)) resourceInputs.setValues(state.resourceURLs);
        if (artwork.isEmpty()) {
            if (state.artworkId) artwork.setArtwork(state.artworkId, state.artworkThumbnailUrl);
            else if (state.artworkExternalURL) artwork.setExternalURL(state.artworkExternalURL);
        }
    }

    // Tracklist management (edit mode)
    const tracklistSection = document.getElementById('editor-tracklist-section');
    const tracklistEl      = document.getElementById('editor-tracklist');
    const trackQueryInput  = document.getElementById('editor-track-query');
    const trackResultsEl   = document.getElementById('editor-track-results');

    function serializeTracklist() {
        if (!tracklistEl || !tracklistJsonInput) return;
        const items = Array.from(tracklistEl.querySelectorAll('li'));
        const tracks = items.map(li => ({
            previewID: li.dataset.previewId || undefined,
            name: li.dataset.trackName || '',
            url: li.dataset.trackUrl || undefined,
        }));
        tracklistJsonInput.value = JSON.stringify(tracks);
    }

    function removeTrack(li) {
        li.remove();
        serializeTracklist();
    }

    function addTrackToList(item) {
        if (!tracklistEl) return;
        const existing = tracklistEl.querySelector(`[data-preview-id="${item.previewID}"]`);
        if (existing) return;
        const template = document.getElementById('editor-track-item-template');
        const li = template.content.cloneNode(true).firstElementChild;
        li.dataset.previewId = item.previewID;
        li.dataset.trackName = item.title;
        if (item.url) li.dataset.trackUrl = item.url;
        li.querySelector('span').textContent = item.title;
        li.querySelector('.track-remove').addEventListener('click', () => removeTrack(li));
        tracklistEl.appendChild(li);
        serializeTracklist();
        if (trackQueryInput) trackQueryInput.value = '';
        if (trackResultsEl) trackResultsEl.hidden = true;
    }

    if (tracklistEl) {
        // Wire existing remove buttons
        tracklistEl.querySelectorAll('.track-remove').forEach(btn => {
            btn.addEventListener('click', () => removeTrack(btn.closest('li')));
        });
        // Populate tracklist-json on page load so it is submitted even without changes
        serializeTracklist();
    }

    if (trackQueryInput && trackResultsEl) {
        let searchTimeout = null;
        trackQueryInput.addEventListener('input', () => {
            clearTimeout(searchTimeout);
            const q = trackQueryInput.value.trim();
            if (!q) { trackResultsEl.hidden = true; return; }
            searchTimeout = setTimeout(async () => {
                try {
                    const res = await fetch(`/playlists/tracks/search?q=${encodeURIComponent(q)}`);
                    if (!res.ok) return;
                    const items = await res.json();
                    trackResultsEl.replaceChildren();
                    if (!items.length) { trackResultsEl.hidden = true; return; }
                    const resultTemplate = document.getElementById('editor-track-result-template');
                    items.slice(0, 10).forEach(item => {
                        const li = resultTemplate.content.cloneNode(true).firstElementChild;
                        li.querySelector('span').textContent = item.title;
                        const small = li.querySelector('small');
                        if (item.subtitle) {
                            small.textContent = ` — ${item.subtitle}`;
                            small.hidden = false;
                        }
                        li.addEventListener('click', () => addTrackToList(item));
                        trackResultsEl.appendChild(li);
                    });
                    trackResultsEl.hidden = false;
                } catch { /* ignore */ }
            }, 300);
        });
        document.addEventListener('click', e => {
            if (!trackResultsEl.contains(e.target) && e.target !== trackQueryInput) {
                trackResultsEl.hidden = true;
            }
        });
    }

    function saveDraft() { persistence.save(storageKey, getState()); }
    function loadDraft() {
        if (persistence.clearIfPending(storageKey)) return;
        const saved = persistence.load(storageKey);
        if (saved) setState(saved);
    }

    const artworkFallbackInput = document.getElementById('editor-artwork-fallback-url');

    function applyMetadata(data) {
        if (!titleInput.value && data.title) titleInput.value = data.title;
        if (!descriptionInput.value && data.description) descriptionInput.value = data.description;
        const resizedURL = data.artwork?.resized;
        if (resizedURL && artwork.isEmpty()) {
            artwork.setExternalURL(resizedURL);
            if (artworkFallbackInput && data.artwork.original) artworkFallbackInput.value = data.artwork.original;
        }
        if (Array.isArray(data.tracks) && data.tracks.length > 0 && tracklistJsonInput) {
            tracklistJsonInput.value = JSON.stringify(data.tracks);
        }
    }

    function fillPreview() {
        const pf = document.getElementById('preview-form');
        if (!pf) return;
        const set = (id, v) => { const el = pf.querySelector(`#${id}`); if (el) el.value = v || ''; };
        set('preview-title',        titleInput?.value || '');
        set('preview-description',  descriptionInput?.value || '');
        set('preview-artwork-url',  artwork.getThumbnailUrl());
        set('preview-resource-urls', resourceInputs.getValues().join('\n'));
        set('preview-notes',        notes.getValues().join('\n\n'));
        pf.submit();
    }

    const autofill = {
        async fetchAndApply(url) {
            try {
                const data = await metadata.fetch(url);
                applyMetadata(data);
                if (statusEl) { statusEl.textContent = ''; statusEl.hidden = true; }
                saveDraft();
            } catch (err) {
                console.error(err);
                handleAutofillError(err, url, statusEl);
            }
        }
    };

    retryPendingMetadata(autofill);
    loadDraft();

    titleInput?.addEventListener('input', saveDraft);
    descriptionInput?.addEventListener('input', saveDraft);

    const imagePicker = new ImagePickerController(
        { gallery, gallerySection, galleryStatus, galleryTitle, notesOpenButton: notesGalleryOpen, galleryCloseButton: galleryClose },
        { onSelectImage: (id, url) => artwork.setArtwork(id, url), onInsertMarkdown: (md) => notes.insertMarkdown(md), imageTitle: 'Select playlist artwork' }
    );
    imagePicker.init();

    new DragAndDropController({ resourcesSection, detailsSection, notesSection }, { uploads, artwork, notes }).init();
    new ShortcutsController([ShortcutsController.login, ShortcutsController.preview(() => fillPreview())]).init();

    document.getElementById('editor-preview')?.addEventListener('click', () => fillPreview());

    form.addEventListener('keydown', (e) => {
        if (e.key !== 'Enter' || e.target.tagName !== 'INPUT') return;
        e.preventDefault();
        const focusable = Array.from(form.querySelectorAll('input:not([type="hidden"]), textarea')).filter(el => !el.disabled);
        const idx = focusable.indexOf(e.target);
        if (idx !== -1 && idx < focusable.length - 1) focusable[idx + 1].focus();
    });

    form.addEventListener('submit', (e) => {
        e.preventDefault();
        persistence.markPendingClear(storageKey);
        form.submit();
    });
});
