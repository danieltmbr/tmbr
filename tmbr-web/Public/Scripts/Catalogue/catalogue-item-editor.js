document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('editor-form');
    if (!form) return;

    const isNew = form.action.endsWith('/new');

    const urlInput         = document.getElementById('editor-url');
    const titleInput       = document.getElementById('editor-title');
    const subtitleInput    = document.getElementById('editor-subtitle');
    const categoryInput    = document.getElementById('editor-category');
    const statusEl         = document.getElementById('autofill-status');
    const resourcesSection = document.getElementById('resources-section');
    const detailsSection   = document.getElementById('details-section');
    const notesSection     = document.getElementById('notes-section');

    const artwork = new ArtworkController(
        {
            hiddenInput:      document.getElementById('editor-artwork-id'),
            externalUrlInput: document.getElementById('editor-artwork-source-url'),
            placeholder:      document.getElementById('artwork-placeholder'),
            imageEl:          document.getElementById('artwork-image'),
            clearButton:      document.getElementById('artwork-clear'),
        },
        { onChange: () => isNew && saveDraft(), onOpenGallery: null }
    );
    artwork.init();

    let notesController = null;
    if (notesSection) {
        notesController = new NotesController(
            { section: notesSection },
            { onInput: () => isNew && saveDraft(), onAccessChange: () => isNew && saveDraft() }
        );
        notesController.init();
    }

    new DragAndDropController(
        { resourcesSection, detailsSection, notesSection },
        { uploads: new UploadsController(), artwork, notes: notesController }
    ).init();

    form.addEventListener('keydown', (e) => {
        if (e.key !== 'Enter' || e.target.tagName !== 'INPUT') return;
        e.preventDefault();
        const focusable = Array.from(form.querySelectorAll('input:not([type="hidden"]), textarea')).filter(el => !el.disabled);
        const idx = focusable.indexOf(e.target);
        if (idx !== -1 && idx < focusable.length - 1) focusable[idx + 1].focus();
    });

    if (!isNew) return;

    // ─── Create-only: draft persistence & URL autofill ────────────────────────

    const persistence = new PersistenceController();
    const storageKey  = 'editor:catalogue:new';
    const metadata    = new MetadataController({ endpoint: '/catalogue/new/metadata' });

    function getState() {
        return {
            url:        urlInput?.value || '',
            title:      titleInput?.value || '',
            subtitle:   subtitleInput?.value || '',
            category:   categoryInput?.value || '',
            notes:      notesController?.getNotes() || [],
            artworkURL: artwork.getExternalURL() || '',
        };
    }

    function setState(state) {
        if (!state || typeof state !== 'object') return;
        if (state.url      && !urlInput?.value)      urlInput.value      = state.url;
        if (state.title    && !titleInput?.value)     titleInput.value    = state.title;
        if (state.subtitle && !subtitleInput?.value)  subtitleInput.value = state.subtitle;
        if (state.category && !categoryInput?.value)  categoryInput.value = state.category;
        if (Array.isArray(state.notes)) notesController?.setNotes(state.notes, true);
        if (state.artworkURL && artwork.isEmpty()) artwork.setExternalURL(state.artworkURL);
    }

    function saveDraft() { persistence.save(storageKey, getState()); }

    function loadDraft() {
        if (persistence.clearIfPending(storageKey)) return;
        const saved = persistence.load(storageKey);
        if (saved) setState(saved);
    }

    const autofill = {
        async fetchAndApply(url) {
            if (!url) return;
            try {
                const data = await metadata.fetch(url);
                if (data.title    && !titleInput?.value.trim())    titleInput.value    = data.title;
                if (data.subtitle && !subtitleInput?.value.trim()) subtitleInput.value = data.subtitle;
                if (data.artworkURL && artwork.isEmpty()) artwork.setExternalURL(data.artworkURL);
                if (statusEl) { statusEl.textContent = ''; statusEl.hidden = true; }
                saveDraft();
            } catch (err) {
                handleAutofillError(err, url, statusEl);
            }
        }
    };

    function fillPreview() {
        const pf = document.getElementById('preview-form');
        if (!pf) return;
        const set = (id, v) => { const el = pf.querySelector(`#${id}`); if (el) el.value = v || ''; };
        set('preview-title',       titleInput?.value || '');
        set('preview-subtitle',    subtitleInput?.value || '');
        set('preview-artwork-url', artwork.getExternalURL() || '');
        set('preview-url',         urlInput?.value || '');
        set('preview-notes',       notesController?.getValues().join('\n\n') || '');
        pf.submit();
    }

    document.getElementById('editor-preview')?.addEventListener('click', fillPreview);

    function checkCategoryHint() {
        const reserved = new Set(['song', 'songs', 'album', 'albums', 'book', 'books', 'movie', 'movies', 'podcast', 'podcasts', 'playlist', 'playlists', 'music']);
        const hint = document.getElementById('category-hint');
        if (!hint || !categoryInput) return;
        const val = categoryInput.value.trim().toLowerCase();
        if (val && reserved.has(val)) {
            hint.textContent = `You already have a ${categoryInput.value.trim()} section — use that for dedicated media.`;
            hint.hidden = false;
        } else {
            hint.textContent = '';
            hint.hidden = true;
        }
    }

    retryPendingMetadata(autofill);
    loadDraft();

    urlInput?.addEventListener('input', saveDraft);
    urlInput?.addEventListener('change', () => autofill.fetchAndApply(urlInput.value.trim()));
    urlInput?.addEventListener('blur',   () => autofill.fetchAndApply(urlInput.value.trim()));
    titleInput?.addEventListener('input',    saveDraft);
    subtitleInput?.addEventListener('input', saveDraft);
    categoryInput?.addEventListener('input', saveDraft);
    categoryInput?.addEventListener('change', checkCategoryHint);
    categoryInput?.addEventListener('blur',   checkCategoryHint);

    form.addEventListener('submit', () => {
        persistence.markPendingClear(storageKey);
    });
});
