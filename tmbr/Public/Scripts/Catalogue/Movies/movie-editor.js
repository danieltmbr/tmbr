class AutofillController {
    constructor({
        titleInput,
        directorInput,
        releaseDateInput,
        statusEl
    }, { metadata, artwork, onApply, lookup, onDuplicate }) {
        this.titleInput = titleInput;
        this.directorInput = directorInput;
        this.releaseDateInput = releaseDateInput;
        this.statusEl = statusEl;
        this.metadata = metadata;
        this.artwork = artwork;
        this.onApply = onApply;
        this.lookup = lookup;
        this.onDuplicate = onDuplicate;
    }

    async fetchAndApply(url) {
        try {
            const lookupPromise = this.lookup
                ? this.lookup.fetch(url).catch(() => null)
                : Promise.resolve(null);
            const [movie, html] = await Promise.all([this.metadata.fetch(url), lookupPromise]);
            this.applyMetadata(movie);
            this.setStatus('');
            if (typeof this.onApply === 'function') this.onApply();
            if (html && typeof this.onDuplicate === 'function') {
                this.onDuplicate(html);
            }
        } catch (error) {
            console.error(error);
            this.setStatus('Failed to fetch metadata.');
        }
    }

    applyMetadata(movie) {
        if (!this.titleInput.value && movie.title) {
            this.titleInput.value = movie.title;
        }
        if (!this.directorInput.value && movie.director) {
            this.directorInput.value = movie.director;
        }
        if (movie.releaseDate) {
            this.releaseDateInput.value = movie.releaseDate.substring(0, 10);
        }
        if (movie.cover && this.artwork.isEmpty()) {
            this.artwork.setExternalURL(movie.cover);
        }
    }

    setStatus(msg, isError = false) {
        if (!this.statusEl) return;
        this.statusEl.textContent = msg;
        this.statusEl.hidden = msg.length === 0;
        this.statusEl.classList.toggle('error', !!isError);
    }
}

class EditorController {
    constructor({
        form,
        idInput,
        titleInput,
        directorInput,
        genreInput,
        releaseDateInput
    }, { persistence, resourceInputs, notes, artwork }) {
        this.form = form;
        this.idInput = idInput;
        this.titleInput = titleInput;
        this.directorInput = directorInput;
        this.genreInput = genreInput;
        this.releaseDateInput = releaseDateInput;
        this.persistence = persistence;
        this.resourceInputs = resourceInputs;
        this.notes = notes;
        this.artwork = artwork;

        this.movieID = this.idInput ? this.idInput.value : '';
        this.storageKey = this.movieID ? `editor:movie:${this.movieID}` : 'editor:movie:new';

        this._onSaveDraft = this.saveDraft.bind(this);
    }

    init() {
        this.loadDraft();
        this.titleInput.addEventListener('input', this._onSaveDraft);
        this.directorInput.addEventListener('input', this._onSaveDraft);
        this.genreInput.addEventListener('input', this._onSaveDraft);
        this.releaseDateInput.addEventListener('input', this._onSaveDraft);
    }

    destroy() {
        this.titleInput.removeEventListener('input', this._onSaveDraft);
        this.directorInput.removeEventListener('input', this._onSaveDraft);
        this.genreInput.removeEventListener('input', this._onSaveDraft);
        this.releaseDateInput.removeEventListener('input', this._onSaveDraft);
    }

    getStorageKey() {
        return this.storageKey;
    }

    preview() {
        const previewForm = document.getElementById('preview-form');
        if (!previewForm) { alert('Preview form is missing from the template.'); return; }
        const set = (id, value) => {
            const el = previewForm.querySelector(`#${id}`);
            if (el) el.value = value || '';
        };
        set('preview-title', this.titleInput.value);
        set('preview-director', this.directorInput.value);
        set('preview-genre', this.genreInput.value);
        set('preview-release-date', this.releaseDateInput.value);
        set('preview-cover-url', this.artwork.getThumbnailUrl());
        set('preview-resource-urls', this.resourceInputs.getValues().join('\n'));
        set('preview-notes', this.notes.getValues().join('\n\n'));
        previewForm.submit();
    }

    getState() {
        return {
            title: this.titleInput.value || '',
            director: this.directorInput.value || '',
            genre: this.genreInput.value || '',
            releaseDate: this.releaseDateInput.value || '',
            notes: this.notes.getNotes(),
            resourceURLs: this.resourceInputs.getValues(),
            artworkId: this.artwork.getArtworkId(),
            artworkThumbnailUrl: this.artwork.getThumbnailUrl(),
            artworkExternalURL: this.artwork.getExternalURL()
        };
    }

    setState(state) {
        if (!state || typeof state !== 'object') return;
        if (typeof state.title === 'string' && !this.titleInput.value) {
            this.titleInput.value = state.title;
        }
        if (typeof state.director === 'string' && !this.directorInput.value) {
            this.directorInput.value = state.director;
        }
        if (typeof state.genre === 'string' && !this.genreInput.value) {
            this.genreInput.value = state.genre;
        }
        if (typeof state.releaseDate === 'string' && !this.releaseDateInput.value) {
            this.releaseDateInput.value = state.releaseDate;
        }
        if (Array.isArray(state.notes)) {
            this.notes.setNotes(state.notes, true);
        }
        if (Array.isArray(state.resourceURLs)) {
            this.resourceInputs.setValues(state.resourceURLs);
        }
        if (this.artwork.isEmpty()) {
            if (state.artworkId) {
                this.artwork.setArtwork(state.artworkId, state.artworkThumbnailUrl);
            } else if (state.artworkExternalURL) {
                this.artwork.setExternalURL(state.artworkExternalURL);
            }
        }
    }

    saveDraft() {
        this.persistence.save(this.storageKey, this.getState());
    }

    loadDraft() {
        if (this.persistence.clearIfPending(this.storageKey)) return;
        const saved = this.persistence.load(this.storageKey);
        if (saved) this.setState(saved);
    }
}


document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('movie-form');
    if (!form) return;

    const persistence = new PersistenceController();
    const uploads = new UploadsController();
    const metadata = new MetadataController({ endpoint: '/movies/metadata' });

    const idInput = document.getElementById('editor-movie-id');
    const titleInput = document.getElementById('editor-movie-title');
    const directorInput = document.getElementById('editor-movie-director');
    const genreInput = document.getElementById('editor-movie-genre');
    const releaseDateInput = document.getElementById('editor-movie-release-date');
    const releaseDateISOInput = document.getElementById('editor-movie-release-date-iso');
    const resourcesSection = document.getElementById('resources-section');
    const detailsSection = document.getElementById('details-section');
    const notesSection = document.getElementById('notes-section');
    const statusEl = document.getElementById('autofill-status');

    const coverIdInput = document.getElementById('editor-cover-id');
    const coverSourceUrlInput = document.getElementById('editor-cover-source-url');
    const artworkPlaceholder = document.getElementById('artwork-placeholder');
    const artworkImage = document.getElementById('artwork-image');
    const artworkClear = document.getElementById('artwork-clear');

    const gallery = document.getElementById('gallery');
    const gallerySection = document.getElementById('gallery-section');
    const galleryStatus = document.getElementById('gallery-status');
    const galleryTitle = document.getElementById('gallery-title');
    const notesGalleryOpen = document.getElementById('notes-gallery-open');
    const galleryClose = document.getElementById('gallery-close');

    const artwork = new ArtworkController({
        hiddenInput: coverIdInput,
        externalUrlInput: coverSourceUrlInput,
        placeholder: artworkPlaceholder,
        imageEl: artworkImage,
        clearButton: artworkClear
    }, {
        onChange: () => editor.saveDraft(),
        onOpenGallery: () => imagePicker.open('image')
    });
    artwork.init();

    const notes = new NotesController(
        { section: notesSection },
        {
            onInput: () => editor.saveDraft(),
            onAccessChange: () => editor.saveDraft()
        }
    );
    notes.init();

    const resourceInputs = new ResourceInputsController(
        { section: resourcesSection },
        {
            onUrlChange: (url) => autofill.fetchAndApply(url),
            onInput: () => editor.saveDraft()
        }
    );
    resourceInputs.init();

    const lookup = new LookupController({
        endpoint: '/movies/lookup',
        excludeID: parseInt(idInput?.value) || null
    });

    const duplicateAlert = new DuplicateAlertController(
        { containerEl: document.getElementById('duplicate-container'), linkSelector: '#duplicate-movie-link' },
        { onNavigate: () => persistence.clear(editor.getStorageKey()) }
    );
    duplicateAlert.init();

    const autofill = new AutofillController({
        titleInput,
        directorInput,
        releaseDateInput,
        statusEl
    }, {
        metadata,
        artwork,
        onApply: () => editor.saveDraft(),
        lookup,
        onDuplicate: (html) => duplicateAlert.show(html)
    });

    const editor = new EditorController({
        form,
        idInput,
        titleInput,
        directorInput,
        genreInput,
        releaseDateInput
    }, { persistence, resourceInputs, notes, artwork });
    editor.init();

    const imagePicker = new ImagePickerController({
        gallery,
        gallerySection,
        galleryStatus,
        galleryTitle,
        notesOpenButton: notesGalleryOpen,
        galleryCloseButton: galleryClose
    }, {
        onSelectImage: (id, thumbnailUrl) => {
            artwork.setArtwork(id, thumbnailUrl);
        },
        onInsertMarkdown: (md) => {
            notes.insertMarkdown(md);
        },
        imageTitle: 'Select movie cover'
    });
    imagePicker.init();

    const dnd = new DragAndDropController({
        resourcesSection,
        detailsSection,
        notesSection
    }, { uploads, artwork, notes });
    dnd.init();

    const shortcuts = new ShortcutsController([
        ShortcutsController.preview(() => editor.preview())
    ]);
    shortcuts.init();

    const previewButton = document.getElementById('editor-movie-preview');
    if (previewButton) {
        previewButton.addEventListener('click', () => editor.preview());
    }

    form.addEventListener('keydown', (e) => {
        if (e.key !== 'Enter' || e.target.tagName !== 'INPUT') return;
        e.preventDefault();
        const focusable = Array.from(form.querySelectorAll('input:not([type="hidden"]), textarea')).filter(el => !el.disabled);
        const idx = focusable.indexOf(e.target);
        if (idx !== -1 && idx < focusable.length - 1) {
            focusable[idx + 1].focus();
        }
    });

    form.addEventListener('submit', (e) => {
        e.preventDefault();

        const date = parseReleaseDate(releaseDateInput.value.trim());
        if (date) {
            releaseDateISOInput.value = date.toISOString();
        } else {
            releaseDateISOInput.disabled = true;
        }

        persistence.markPendingClear(editor.getStorageKey());
        form.submit();
    });
});
