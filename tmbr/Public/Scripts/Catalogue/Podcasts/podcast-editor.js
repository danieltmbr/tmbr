document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('editor-form');
    if (!form) return;

    // editor-title holds the episode title (form field name: episodeTitle)
    const idInput             = document.getElementById('editor-id');
    const episodeTitleInput   = document.getElementById('editor-title');
    const showTitleInput      = document.getElementById('editor-show-title');
    const genreInput          = document.getElementById('editor-genre');
    const releaseDateInput    = document.getElementById('editor-release-date');
    const releaseDateISOInput = document.getElementById('editor-release-date-iso');
    const seasonNumberInput   = document.getElementById('editor-season-number');
    const episodeNumberInput  = document.getElementById('editor-episode-number');
    const statusEl            = document.getElementById('autofill-status');

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
    const metadata    = new MetadataController({ endpoint: '/podcasts/metadata' });

    const itemID     = idInput?.value || '';
    const storageKey = itemID ? `editor:podcast:${itemID}` : 'editor:podcast:new';

    const artwork = new ArtworkController({
        hiddenInput:      document.getElementById('editor-artwork-id'),
        externalUrlInput: document.getElementById('editor-artwork-source-url'),
        placeholder:      document.getElementById('cover-placeholder'),
        imageEl:          document.getElementById('cover-image'),
        clearButton:      document.getElementById('cover-clear'),
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

    const lookup = new LookupController({ endpoint: '/podcasts/lookup', excludeID: parseInt(idInput?.value) || null });

    const duplicateAlert = new DuplicateAlertController(
        { containerEl: document.getElementById('duplicate-container'), linkSelector: '#duplicate-podcast-link' },
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
            episodeTitle:       episodeTitleInput?.value || '',
            showTitle:          showTitleInput?.value || '',
            genre:              genreInput?.value || '',
            releaseDate:        releaseDateInput?.value || '',
            seasonNumber:       seasonNumberInput?.value || '',
            episodeNumber:      episodeNumberInput?.value || '',
            notes:              notes.getNotes(),
            resourceURLs:       resourceInputs.getValues(),
            artworkId:          artwork.getArtworkId(),
            artworkThumbnailUrl: artwork.getThumbnailUrl(),
            artworkExternalURL: artwork.getExternalURL(),
        };
    }

    function setState(state) {
        if (!state || typeof state !== 'object') return;
        if (typeof state.episodeTitle === 'string' && !episodeTitleInput.value) episodeTitleInput.value = state.episodeTitle;
        if (typeof state.showTitle === 'string' && !showTitleInput.value) showTitleInput.value = state.showTitle;
        if (typeof state.genre === 'string' && !genreInput.value) genreInput.value = state.genre;
        if (typeof state.releaseDate === 'string' && !releaseDateInput.value) releaseDateInput.value = state.releaseDate;
        if (typeof state.seasonNumber === 'string' && !seasonNumberInput.value) seasonNumberInput.value = state.seasonNumber;
        if (typeof state.episodeNumber === 'string' && !episodeNumberInput.value) episodeNumberInput.value = state.episodeNumber;
        if (Array.isArray(state.notes)) notes.setNotes(state.notes, true);
        if (Array.isArray(state.resourceURLs)) resourceInputs.setValues(state.resourceURLs);
        if (artwork.isEmpty()) {
            if (state.artworkId) artwork.setArtwork(state.artworkId, state.artworkThumbnailUrl);
            else if (state.artworkExternalURL) artwork.setExternalURL(state.artworkExternalURL);
        }
    }

    function saveDraft() { persistence.save(storageKey, getState()); }
    function loadDraft() {
        if (persistence.clearIfPending(storageKey)) return;
        const saved = persistence.load(storageKey);
        if (saved) setState(saved);
    }

    function applyMetadata(data) {
        if (!episodeTitleInput.value && data.episodeTitle) episodeTitleInput.value = data.episodeTitle;
        if (!showTitleInput.value && data.showTitle) showTitleInput.value = data.showTitle;
        if (!genreInput.value && data.genre) genreInput.value = data.genre;
        if (data.releaseDate) releaseDateInput.value = data.releaseDate.substring(0, 10);
        if (!seasonNumberInput.value && data.seasonNumber) seasonNumberInput.value = data.seasonNumber;
        if (!episodeNumberInput.value && data.episodeNumber) episodeNumberInput.value = data.episodeNumber;
        if (data.artwork && artwork.isEmpty()) artwork.setExternalURL(data.artwork);
    }

    function fillPreview() {
        const pf = document.getElementById('preview-form');
        if (!pf) return;
        const set = (id, v) => { const el = pf.querySelector(`#${id}`); if (el) el.value = v || ''; };
        set('preview-episode-title', episodeTitleInput?.value || '');
        set('preview-title',         showTitleInput?.value || '');
        set('preview-genre',         genreInput?.value || '');
        set('preview-release-date',  releaseDateInput?.value || '');
        set('preview-season-number', seasonNumberInput?.value || '');
        set('preview-episode-number', episodeNumberInput?.value || '');
        set('preview-artwork-url',   artwork.getThumbnailUrl());
        set('preview-resource-urls', resourceInputs.getValues().join('\n'));
        set('preview-notes',         notes.getValues().join('\n\n'));
        pf.submit();
    }

    const autofill = {
        async fetchAndApply(url) {
            try {
                const [data, html] = await Promise.all([metadata.fetch(url), lookup.fetch(url).catch(() => null)]);
                applyMetadata(data);
                if (statusEl) { statusEl.textContent = ''; statusEl.hidden = true; }
                saveDraft();
                if (html) duplicateAlert.show(html);
            } catch (err) {
                console.error(err);
                handleAutofillError(err, url, statusEl);
            }
        }
    };

    retryPendingMetadata(autofill);
    loadDraft();

    episodeTitleInput?.addEventListener('input', saveDraft);
    showTitleInput?.addEventListener('input', saveDraft);
    genreInput?.addEventListener('input', saveDraft);
    releaseDateInput?.addEventListener('input', saveDraft);
    seasonNumberInput?.addEventListener('input', saveDraft);
    episodeNumberInput?.addEventListener('input', saveDraft);

    const imagePicker = new ImagePickerController(
        { gallery, gallerySection, galleryStatus, galleryTitle, notesOpenButton: notesGalleryOpen, galleryCloseButton: galleryClose },
        { onSelectImage: (id, url) => artwork.setArtwork(id, url), onInsertMarkdown: (md) => notes.insertMarkdown(md), imageTitle: 'Select podcast artwork' }
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
        const date = parseReleaseDate(releaseDateInput.value.trim());
        if (date) releaseDateISOInput.value = date.toISOString();
        else releaseDateISOInput.disabled = true;
        persistence.markPendingClear(storageKey);
        form.submit();
    });
});
