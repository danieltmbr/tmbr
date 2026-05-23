document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('editor-form');
    if (!form) return;

    const idInput             = document.getElementById('editor-id');
    const titleInput          = document.getElementById('editor-title');
    const authorInput         = document.getElementById('editor-author');
    const genreInput          = document.getElementById('editor-genre');
    const releaseDateInput    = document.getElementById('editor-release-date');
    const releaseDateISOInput = document.getElementById('editor-release-date-iso');
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
    const metadata    = new MetadataController({ endpoint: '/books/metadata' });

    const itemID     = idInput?.value || '';
    const storageKey = itemID ? `editor:book:${itemID}` : 'editor:book:new';

    const artwork = new ArtworkController({
        hiddenInput:      document.getElementById('editor-cover-id'),
        externalUrlInput: document.getElementById('editor-cover-source-url'),
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

    const lookup = new LookupController({ endpoint: '/books/lookup', excludeID: parseInt(idInput?.value) || null });

    const duplicateAlert = new DuplicateAlertController(
        { containerEl: document.getElementById('duplicate-container'), linkSelector: '#duplicate-book-link' },
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
            author:             authorInput?.value || '',
            genre:              genreInput?.value || '',
            releaseDate:        releaseDateInput?.value || '',
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
        if (typeof state.author === 'string' && !authorInput.value) authorInput.value = state.author;
        if (typeof state.genre === 'string' && !genreInput.value) genreInput.value = state.genre;
        if (typeof state.releaseDate === 'string' && !releaseDateInput.value) releaseDateInput.value = state.releaseDate;
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
        if (!titleInput.value && data.title) titleInput.value = data.title;
        if (!authorInput.value && data.author) authorInput.value = data.author;
        if (!genreInput.value && data.genre) genreInput.value = data.genre;
        if (data.releaseDate) releaseDateInput.value = data.releaseDate.substring(0, 10);
        // Books API returns 'cover', not 'artwork'
        if (data.cover && artwork.isEmpty()) artwork.setExternalURL(data.cover);
    }

    function fillPreview() {
        const pf = document.getElementById('preview-form');
        if (!pf) return;
        const set = (id, v) => { const el = pf.querySelector(`#${id}`); if (el) el.value = v || ''; };
        set('preview-title',        titleInput?.value || '');
        set('preview-author',       authorInput?.value || '');
        set('preview-genre',        genreInput?.value || '');
        set('preview-release-date', releaseDateInput?.value || '');
        set('preview-artwork-url',  artwork.getThumbnailUrl());
        set('preview-resource-urls', resourceInputs.getValues().join('\n'));
        set('preview-notes',        notes.getValues().join('\n\n'));
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

    titleInput?.addEventListener('input', saveDraft);
    authorInput?.addEventListener('input', saveDraft);
    genreInput?.addEventListener('input', saveDraft);
    releaseDateInput?.addEventListener('input', saveDraft);

    const imagePicker = new ImagePickerController(
        { gallery, gallerySection, galleryStatus, galleryTitle, notesOpenButton: notesGalleryOpen, galleryCloseButton: galleryClose },
        { onSelectImage: (id, url) => artwork.setArtwork(id, url), onInsertMarkdown: (md) => notes.insertMarkdown(md), imageTitle: 'Select book cover' }
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
