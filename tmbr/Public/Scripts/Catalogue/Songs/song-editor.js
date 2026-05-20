class AutofillController {
    constructor({
        titleInput,
        artistInput,
        albumInput,
        releaseDateInput,
        statusEl
    }, { metadata, artwork, onApply, lookup, onDuplicate }) {
        this.titleInput = titleInput;
        this.artistInput = artistInput;
        this.albumInput = albumInput;
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
            const [song, html] = await Promise.all([this.metadata.fetch(url), lookupPromise]);
            this.applyMetadata(song);
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

    applyMetadata(song) {
        if (!this.titleInput.value && song.title) {
            this.titleInput.value = song.title;
        }
        if (!this.artistInput.value && song.artist) {
            this.artistInput.value = song.artist;
        }
        if (!this.albumInput.value && song.album) {
            this.albumInput.value = song.album;
        }
        if (song.releaseDate) {
            this.releaseDateInput.value = song.releaseDate.substring(0, 10);
        }
        if (song.artwork && this.artwork.isEmpty()) {
            this.artwork.setExternalURL(song.artwork);
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
        artistInput,
        albumInput,
        genreInput,
        releaseDateInput
    }, { persistence, resourceInputs, notes, artwork }) {
        this.form = form;
        this.idInput = idInput;
        this.titleInput = titleInput;
        this.artistInput = artistInput;
        this.albumInput = albumInput;
        this.genreInput = genreInput;
        this.releaseDateInput = releaseDateInput;
        this.persistence = persistence;
        this.resourceInputs = resourceInputs;
        this.notes = notes;
        this.artwork = artwork;

        this.songID = this.idInput ? this.idInput.value : '';
        this.storageKey = this.songID ? `editor:song:${this.songID}` : 'editor:song:new';

        this._onSaveDraft = this.saveDraft.bind(this);
    }

    init() {
        this.loadDraft();

        this.titleInput.addEventListener('input', this._onSaveDraft);
        this.artistInput.addEventListener('input', this._onSaveDraft);
        this.albumInput.addEventListener('input', this._onSaveDraft);
        this.genreInput.addEventListener('input', this._onSaveDraft);
        this.releaseDateInput.addEventListener('input', this._onSaveDraft);
    }

    destroy() {
        this.titleInput.removeEventListener('input', this._onSaveDraft);
        this.artistInput.removeEventListener('input', this._onSaveDraft);
        this.albumInput.removeEventListener('input', this._onSaveDraft);
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
        set('preview-artist', this.artistInput.value);
        set('preview-album', this.albumInput.value);
        set('preview-genre', this.genreInput.value);
        set('preview-release-date', this.releaseDateInput.value);
        set('preview-artwork-url', this.artwork.getThumbnailUrl());
        set('preview-resource-urls', this.resourceInputs.getValues().join('\n'));
        set('preview-notes', this.notes.getValues().join('\n\n'));
        previewForm.submit();
    }

    getState() {
        return {
            title: this.titleInput.value || '',
            artist: this.artistInput.value || '',
            album: this.albumInput.value || '',
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
        if (typeof state.artist === 'string' && !this.artistInput.value) {
            this.artistInput.value = state.artist;
        }
        if (typeof state.album === 'string' && !this.albumInput.value) {
            this.albumInput.value = state.album;
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
        if (this.persistence.clearIfPending(this.storageKey)) {
            return;
        }
        const saved = this.persistence.load(this.storageKey);
        if (saved) this.setState(saved);
    }
}


document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('song-form');
    if (!form) return;

    const persistence = new PersistenceController();
    const uploads = new UploadsController();
    const metadata = new MetadataController({ endpoint: '/songs/metadata' });

    const idInput = document.getElementById('editor-song-id');
    const titleInput = document.getElementById('editor-song-title');
    const artistInput = document.getElementById('editor-song-artist');
    const albumInput = document.getElementById('editor-song-album');
    const genreInput = document.getElementById('editor-song-genre');
    const releaseDateInput = document.getElementById('editor-song-release-date');
    const releaseDateISOInput = document.getElementById('editor-song-release-date-iso');
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
        endpoint: '/songs/lookup',
        excludeID: parseInt(idInput?.value) || null
    });

    const duplicateAlert = new DuplicateAlertController(
        { containerEl: document.getElementById('duplicate-container'), linkSelector: '#duplicate-song-link' },
        { onNavigate: () => persistence.clear(editor.getStorageKey()) }
    );
    duplicateAlert.init();

    const autofill = new AutofillController({
        titleInput,
        artistInput,
        albumInput,
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
        artistInput,
        albumInput,
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
        imageTitle: 'Select album artwork'
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

    const previewButton = document.getElementById('editor-song-preview');
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

        const dateValue = releaseDateInput.value.trim();
        if (dateValue) {
            const normalized = /^\d{4}$/.test(dateValue) ? `${dateValue}-01-01` : dateValue.replace(/[\s\-]/g, '/');
            const date = new Date(normalized);
            if (!isNaN(date.getTime())) {
                releaseDateISOInput.value = date.toISOString();
            } else {
                releaseDateISOInput.disabled = true;
            }
        } else {
            releaseDateISOInput.disabled = true;
        }

        persistence.markPendingClear(editor.getStorageKey());
        form.submit();
    });
});
