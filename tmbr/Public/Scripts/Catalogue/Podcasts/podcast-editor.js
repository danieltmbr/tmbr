class AutofillController {
    constructor({
        episodeTitleInput,
        titleInput,
        releaseDateInput,
        seasonNumberInput,
        episodeNumberInput,
        statusEl
    }, { metadata, artwork, onApply, lookup, onDuplicate }) {
        this.episodeTitleInput = episodeTitleInput;
        this.titleInput = titleInput;
        this.releaseDateInput = releaseDateInput;
        this.seasonNumberInput = seasonNumberInput;
        this.episodeNumberInput = episodeNumberInput;
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
            const [podcast, html] = await Promise.all([this.metadata.fetch(url), lookupPromise]);
            this.applyMetadata(podcast);
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

    applyMetadata(podcast) {
        if (!this.episodeTitleInput.value && podcast.episodeTitle) {
            this.episodeTitleInput.value = podcast.episodeTitle;
        }
        if (!this.titleInput.value && podcast.showTitle) {
            this.titleInput.value = podcast.showTitle;
        }
        if (podcast.releaseDate) {
            this.releaseDateInput.value = podcast.releaseDate.substring(0, 10);
        }
        if (podcast.seasonNumber != null && !this.seasonNumberInput.value) {
            this.seasonNumberInput.value = podcast.seasonNumber;
        }
        if (podcast.episodeNumber != null && !this.episodeNumberInput.value) {
            this.episodeNumberInput.value = podcast.episodeNumber;
        }
        if (podcast.artwork && this.artwork.isEmpty()) {
            this.artwork.setExternalURL(podcast.artwork);
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
        episodeTitleInput,
        titleInput,
        genreInput,
        releaseDateInput,
        seasonNumberInput,
        episodeNumberInput
    }, { persistence, resourceInputs, notes, artwork }) {
        this.form = form;
        this.idInput = idInput;
        this.episodeTitleInput = episodeTitleInput;
        this.titleInput = titleInput;
        this.genreInput = genreInput;
        this.releaseDateInput = releaseDateInput;
        this.seasonNumberInput = seasonNumberInput;
        this.episodeNumberInput = episodeNumberInput;
        this.persistence = persistence;
        this.resourceInputs = resourceInputs;
        this.notes = notes;
        this.artwork = artwork;

        this.podcastID = this.idInput ? this.idInput.value : '';
        this.storageKey = this.podcastID ? `editor:podcast:${this.podcastID}` : 'editor:podcast:new';

        this._onSaveDraft = this.saveDraft.bind(this);
    }

    init() {
        this.loadDraft();
        this.episodeTitleInput.addEventListener('input', this._onSaveDraft);
        this.titleInput.addEventListener('input', this._onSaveDraft);
        this.genreInput.addEventListener('input', this._onSaveDraft);
        this.releaseDateInput.addEventListener('input', this._onSaveDraft);
        this.seasonNumberInput?.addEventListener('input', this._onSaveDraft);
        this.episodeNumberInput?.addEventListener('input', this._onSaveDraft);
    }

    destroy() {
        this.episodeTitleInput.removeEventListener('input', this._onSaveDraft);
        this.titleInput.removeEventListener('input', this._onSaveDraft);
        this.genreInput.removeEventListener('input', this._onSaveDraft);
        this.releaseDateInput.removeEventListener('input', this._onSaveDraft);
        this.seasonNumberInput?.removeEventListener('input', this._onSaveDraft);
        this.episodeNumberInput?.removeEventListener('input', this._onSaveDraft);
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
        set('preview-episode-title', this.episodeTitleInput.value);
        set('preview-title', this.titleInput.value);
        set('preview-genre', this.genreInput.value);
        set('preview-release-date', this.releaseDateInput.value);
        set('preview-artwork-url', this.artwork.getThumbnailUrl());
        set('preview-resource-urls', this.resourceInputs.getValues().join('\n'));
        set('preview-notes', this.notes.getValues().join('\n\n'));
        set('preview-season-number', this.seasonNumberInput?.value || '');
        set('preview-episode-number', this.episodeNumberInput?.value || '');
        previewForm.submit();
    }

    getState() {
        return {
            episodeTitle: this.episodeTitleInput.value || '',
            title: this.titleInput.value || '',
            genre: this.genreInput.value || '',
            releaseDate: this.releaseDateInput.value || '',
            seasonNumber: this.seasonNumberInput?.value || '',
            episodeNumber: this.episodeNumberInput?.value || '',
            notes: this.notes.getNotes(),
            resourceURLs: this.resourceInputs.getValues(),
            artworkId: this.artwork.getArtworkId(),
            artworkThumbnailUrl: this.artwork.getThumbnailUrl(),
            artworkExternalURL: this.artwork.getExternalURL()
        };
    }

    setState(state) {
        if (!state || typeof state !== 'object') return;
        if (typeof state.episodeTitle === 'string' && !this.episodeTitleInput.value) {
            this.episodeTitleInput.value = state.episodeTitle;
        }
        if (typeof state.title === 'string' && !this.titleInput.value) {
            this.titleInput.value = state.title;
        }
        if (typeof state.genre === 'string' && !this.genreInput.value) {
            this.genreInput.value = state.genre;
        }
        if (typeof state.releaseDate === 'string' && !this.releaseDateInput.value) {
            this.releaseDateInput.value = state.releaseDate;
        }
        if (typeof state.seasonNumber === 'string' && this.seasonNumberInput && !this.seasonNumberInput.value) {
            this.seasonNumberInput.value = state.seasonNumber;
        }
        if (typeof state.episodeNumber === 'string' && this.episodeNumberInput && !this.episodeNumberInput.value) {
            this.episodeNumberInput.value = state.episodeNumber;
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
    const form = document.getElementById('podcast-form');
    if (!form) return;

    const persistence = new PersistenceController();
    const uploads = new UploadsController();
    const metadata = new MetadataController({ endpoint: '/podcasts/metadata' });

    const idInput = document.getElementById('editor-podcast-id');
    const episodeTitleInput = document.getElementById('editor-podcast-episode-title');
    const titleInput = document.getElementById('editor-podcast-title');
    const genreInput = document.getElementById('editor-podcast-genre');
    const releaseDateInput = document.getElementById('editor-podcast-release-date');
    const releaseDateISOInput = document.getElementById('editor-podcast-release-date-iso');
    const seasonNumberInput = document.getElementById('editor-podcast-season-number');
    const episodeNumberInput = document.getElementById('editor-podcast-episode-number');
    const resourcesSection = document.getElementById('resources-section');
    const detailsSection = document.getElementById('details-section');
    const notesSection = document.getElementById('notes-section');
    const statusEl = document.getElementById('autofill-status');

    const artworkIdInput = document.getElementById('editor-artwork-id');
    const artworkSourceUrlInput = document.getElementById('editor-artwork-source-url');
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
        hiddenInput: artworkIdInput,
        externalUrlInput: artworkSourceUrlInput,
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
        endpoint: '/podcasts/lookup',
        excludeID: parseInt(idInput?.value) || null
    });

    const duplicateAlert = new DuplicateAlertController(
        { containerEl: document.getElementById('duplicate-container'), linkSelector: '#duplicate-podcast-link' },
        { onNavigate: () => persistence.clear(editor.getStorageKey()) }
    );
    duplicateAlert.init();

    const autofill = new AutofillController({
        episodeTitleInput,
        titleInput,
        releaseDateInput,
        seasonNumberInput,
        episodeNumberInput,
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
        episodeTitleInput,
        titleInput,
        genreInput,
        releaseDateInput,
        seasonNumberInput,
        episodeNumberInput
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
        imageTitle: 'Select podcast artwork'
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

    const previewButton = document.getElementById('editor-podcast-preview');
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
