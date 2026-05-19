class MetadataController {
    constructor({ endpoint = "/books/metadata" } = {}) {
        this.endpoint = endpoint;
    }

    async fetch(url) {
        if (!url || typeof url !== 'string') {
            throw new Error('A valid URL is required to fetch book metadata.');
        }
        const encoded = encodeURIComponent(url);
        const response = await window.fetch(`${this.endpoint}?url=${encoded}`);
        if (!response.ok) throw new Error(`Metadata fetch failed (${response.status})`);
        return await response.json();
    }
}

class LookupController {
    constructor({ endpoint = '/books/lookup', excludeID = null } = {}) {
        this.endpoint = endpoint;
        this.excludeID = excludeID;
    }

    async fetch(url) {
        const params = new URLSearchParams({ url });
        if (this.excludeID) params.set('excludeID', String(this.excludeID));
        const response = await window.fetch(`${this.endpoint}?${params}`, {
            headers: { Accept: 'text/html' }
        });
        if (!response.ok) return null;
        return await response.text();
    }
}

class DuplicateAlertController {
    constructor({ containerEl }, { onNavigate } = {}) {
        this.containerEl = containerEl;
        this.dialogEl = null;
        this.dismissEl = null;
        this.linkEl = null;
        this._onDismiss = null;
        this._onNavigate = () => { if (typeof onNavigate === 'function') onNavigate(); };
    }

    init() {}

    destroy() {
        this._detach();
    }

    _detach() {
        this.dismissEl?.removeEventListener('click', this._onDismiss);
        this.linkEl?.removeEventListener('click', this._onNavigate);
    }

    show(html) {
        if (!this.containerEl || !html) return;
        this._detach();
        this.containerEl.innerHTML = html;
        this.dialogEl = this.containerEl.querySelector('dialog');
        this.dismissEl = this.containerEl.querySelector('#duplicate-dismiss');
        this.linkEl = this.containerEl.querySelector('#duplicate-book-link');
        this._onDismiss = () => this.dialogEl?.close();
        this.dismissEl?.addEventListener('click', this._onDismiss);
        this.linkEl?.addEventListener('click', this._onNavigate);
        this.dialogEl?.showModal();
    }
}

class AutofillController {
    constructor({
        titleInput,
        authorInput,
        releaseDateInput,
        statusEl
    }, { metadata, artwork, onApply, lookup, onDuplicate }) {
        this.titleInput = titleInput;
        this.authorInput = authorInput;
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
            const [book, html] = await Promise.all([this.metadata.fetch(url), lookupPromise]);
            this.applyMetadata(book);
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

    applyMetadata(book) {
        if (!this.titleInput.value && book.title) {
            this.titleInput.value = book.title;
        }
        if (!this.authorInput.value && book.author) {
            this.authorInput.value = book.author;
        }
        if (book.releaseDate) {
            this.releaseDateInput.value = book.releaseDate.substring(0, 10);
        }
        if (book.cover && this.artwork.isEmpty()) {
            this.artwork.setExternalURL(book.cover);
        }
    }

    setStatus(msg, isError = false) {
        if (!this.statusEl) return;
        this.statusEl.textContent = msg;
        this.statusEl.hidden = msg.length === 0;
        this.statusEl.classList.toggle('error', !!isError);
    }
}

class GalleryController {
    constructor({
        gallery,
        gallerySection,
        galleryStatus,
        galleryTitle,
        notesOpenButton,
        galleryCloseButton
    }, { onSelectCover, onInsertMarkdown }) {
        this.gallery = gallery;
        this.gallerySection = gallerySection;
        this.galleryStatus = galleryStatus;
        this.galleryTitle = galleryTitle;
        this.notesOpenButton = notesOpenButton;
        this.galleryCloseButton = galleryCloseButton;
        this.onSelectCover = onSelectCover;
        this.onInsertMarkdown = onInsertMarkdown;
        this.mode = 'cover';
        this._onNotesOpen = () => this.open('notes');
        this._onClose = this.close.bind(this);
    }

    init() {
        if (this.notesOpenButton) {
            this.notesOpenButton.addEventListener('click', this._onNotesOpen);
        }
        this.galleryCloseButton.addEventListener('click', this._onClose);
    }

    destroy() {
        if (this.notesOpenButton) {
            this.notesOpenButton.removeEventListener('click', this._onNotesOpen);
        }
        this.galleryCloseButton.removeEventListener('click', this._onClose);
    }

    async open(mode) {
        this.mode = mode;
        this.galleryTitle.textContent = mode === 'cover' ? 'Select book cover' : 'Insert into note';
        this.gallery.classList.add("open");
        this.galleryStatus.innerHTML = 'Loading...';
        try {
            const res = await fetch('/gallery?embedded=true', { headers: { 'Accept': 'text/html' }});
            const html = await res.text();
            this.gallerySection.innerHTML = html;
            this.attachListenersToGallery();
            this.galleryStatus.innerHTML = '';
        } catch (err) {
            this.galleryStatus.innerHTML = 'Failed to load gallery.';
            console.error(`Gallery load failed: ${err?.message || err}`);
        }
    }

    close() {
        this.gallery.classList.remove("open");
    }

    attachListenersToGallery() {
        const galleryItems = this.gallerySection.querySelectorAll('.gallery-item');

        galleryItems.forEach((btn) => {
            const id = btn.dataset.id;
            const alt = btn.dataset.alt || '';
            const url = btn.dataset.url;
            const thumbnailUrl = btn.querySelector('img')?.src || url;
            if (!url) return;

            const markdown = `![${alt}](${url})`;

            btn.addEventListener('click', () => {
                if (this.mode === 'cover') {
                    if (typeof this.onSelectCover === 'function') {
                        this.onSelectCover(id, thumbnailUrl);
                    }
                } else {
                    if (typeof this.onInsertMarkdown === 'function') {
                        this.onInsertMarkdown(markdown);
                    }
                }
                this.close();
            });

            btn.addEventListener('dragstart', (e) => {
                e.dataTransfer.setData('text/uri-list', url);
                e.dataTransfer.setData('text/plain', url);
                e.dataTransfer.setData('text/html', `<img src="${url}" alt="${alt}">`);
                e.dataTransfer.setData('application/x-editor-markdown', markdown);
                e.dataTransfer.setData('application/x-editor-image-id', id);
                e.dataTransfer.setData('application/x-editor-thumbnail-url', thumbnailUrl);
                e.dataTransfer.effectAllowed = 'copy';
            });
        });
    }
}

class DragAndDropController {
    constructor({ resourcesSection, detailsSection, notesSection }, { uploads, artwork, notes }) {
        this.resourcesSection = resourcesSection;
        this.detailsSection = detailsSection;
        this.notesSection = notesSection;
        this.uploads = uploads;
        this.artwork = artwork;
        this.notes = notes;
        this.hideTimer = null;
        this._onDragEnter = this.onDragEnter.bind(this);
        this._onDragOver = this.onDragOver.bind(this);
        this._onDragLeave = this.onDragLeave.bind(this);
        this._onDrop = this.onDrop.bind(this);
    }

    init() {
        window.addEventListener('dragenter', this._onDragEnter);
        window.addEventListener('dragover', this._onDragOver);
        window.addEventListener('dragleave', this._onDragLeave);
        window.addEventListener('drop', this._onDrop, { capture: true });
    }

    destroy() {
        window.removeEventListener('dragenter', this._onDragEnter);
        window.removeEventListener('dragover', this._onDragOver);
        window.removeEventListener('dragleave', this._onDragLeave);
        window.removeEventListener('drop', this._onDrop, { capture: true });
    }

    shouldShowCue(e) {
        const dt = e.dataTransfer;
        if (!dt) return false;
        if (dt.items && dt.items.length) {
            for (const item of dt.items) {
                if (item.kind === 'file') {
                    if (!item.type || item.type.startsWith('image/')) return true;
                }
            }
            return false;
        }
        if (dt.files && dt.files.length) {
            const files = Array.from(dt.files);
            if (files.every(f => f.type)) return files.some(f => f.type.startsWith('image/'));
            return true;
        }
        return true;
    }

    showCue(target) {
        document.body.classList.add('dragging-page');
        document.body.classList.toggle('dragging-target-details', target === 'details');
        document.body.classList.toggle('dragging-target-notes', target === 'notes');
        if (this.hideTimer) { clearTimeout(this.hideTimer); this.hideTimer = null; }
    }

    hideCueDebounced() {
        if (this.hideTimer) clearTimeout(this.hideTimer);
        this.hideTimer = setTimeout(() => {
            document.body.classList.remove('dragging-page', 'dragging-target-details', 'dragging-target-notes');
        }, 60);
    }

    onDragEnter(e) {
        if (this.shouldShowCue(e)) this.showCue(this.getDropTarget(e));
    }

    onDragOver(e) {
        e.preventDefault();
        if (this.shouldShowCue(e)) this.showCue(this.getDropTarget(e));
        else this.hideCueDebounced();
    }

    onDragLeave() {
        this.hideCueDebounced();
    }

    getDropTarget(e) {
        const target = e.target;
        if (this.notesSection && this.notesSection.contains(target)) return 'notes';
        return 'details';
    }

    async onDrop(e) {
        e.preventDefault();
        document.body.classList.remove('dragging-page', 'dragging-target-details', 'dragging-target-notes');
        const dt = e.dataTransfer;
        if (!dt) return;

        const dropTarget = this.getDropTarget(e);
        const customMarkdown = dt.getData('application/x-editor-markdown') || '';
        const imageId = dt.getData('application/x-editor-image-id') || '';
        const thumbnailUrl = dt.getData('application/x-editor-thumbnail-url') || '';

        if (imageId && dropTarget === 'details') {
            this.artwork.setArtwork(imageId, thumbnailUrl);
            return;
        }
        if (customMarkdown && dropTarget === 'notes') {
            this.notes.insertMarkdown(customMarkdown);
            return;
        }

        const files = Array.from(dt.files || []);
        if (!files.length) return;
        const imageFiles = files.filter(f => f && (!f.type || f.type.startsWith('image/')));
        if (!imageFiles.length) return;

        if (dropTarget === 'details') {
            const file = imageFiles[0];
            try {
                const markdown = await this.uploads.uploadImageFile(file);
                const match = markdown.match(/!\[([^\]]*)\]\(([^)]+)\)/);
                if (match) {
                    const url = match[2];
                    const response = await fetch('/gallery?embedded=true', { headers: { 'Accept': 'text/html' }});
                    const html = await response.text();
                    const parser = new DOMParser();
                    const doc = parser.parseFromString(html, 'text/html');
                    const item = doc.querySelector(`.gallery-item[data-url="${url}"]`);
                    if (item) {
                        const id = item.dataset.id;
                        const thumb = item.querySelector('img')?.src || url;
                        this.artwork.setArtwork(id, thumb);
                    }
                }
            } catch (err) {
                console.error(`Image upload failed: ${err?.message || err}`);
            }
        } else {
            for (const file of imageFiles) {
                try {
                    const markdown = await this.uploads.uploadImageFile(file);
                    this.notes.insertMarkdown(markdown);
                } catch (err) {
                    console.error(`Image upload failed: ${err?.message || err}`);
                }
            }
        }
    }
}

class EditorController {
    constructor({
        form,
        idInput,
        titleInput,
        authorInput,
        genreInput,
        releaseDateInput
    }, { persistence, resourceInputs, notes, artwork }) {
        this.form = form;
        this.idInput = idInput;
        this.titleInput = titleInput;
        this.authorInput = authorInput;
        this.genreInput = genreInput;
        this.releaseDateInput = releaseDateInput;
        this.persistence = persistence;
        this.resourceInputs = resourceInputs;
        this.notes = notes;
        this.artwork = artwork;

        this.bookID = this.idInput ? this.idInput.value : '';
        this.storageKey = this.bookID ? `editor:book:${this.bookID}` : 'editor:book:new';

        this._onSaveDraft = this.saveDraft.bind(this);
    }

    init() {
        this.loadDraft();
        this.titleInput.addEventListener('input', this._onSaveDraft);
        this.authorInput.addEventListener('input', this._onSaveDraft);
        this.genreInput.addEventListener('input', this._onSaveDraft);
        this.releaseDateInput.addEventListener('input', this._onSaveDraft);
    }

    destroy() {
        this.titleInput.removeEventListener('input', this._onSaveDraft);
        this.authorInput.removeEventListener('input', this._onSaveDraft);
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
        set('preview-author', this.authorInput.value);
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
            author: this.authorInput.value || '',
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
        if (typeof state.author === 'string' && !this.authorInput.value) {
            this.authorInput.value = state.author;
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
    const form = document.getElementById('book-form');
    if (!form) return;

    const persistence = new PersistenceController();
    const uploads = new UploadsController();
    const metadata = new MetadataController();

    const idInput = document.getElementById('editor-book-id');
    const titleInput = document.getElementById('editor-book-title');
    const authorInput = document.getElementById('editor-book-author');
    const genreInput = document.getElementById('editor-book-genre');
    const releaseDateInput = document.getElementById('editor-book-release-date');
    const releaseDateISOInput = document.getElementById('editor-book-release-date-iso');
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
        onOpenGallery: () => galleryController.open('cover')
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
        excludeID: parseInt(idInput?.value) || null
    });

    const duplicateAlert = new DuplicateAlertController(
        { containerEl: document.getElementById('duplicate-container') },
        { onNavigate: () => persistence.clear(editor.getStorageKey()) }
    );
    duplicateAlert.init();

    const autofill = new AutofillController({
        titleInput,
        authorInput,
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
        authorInput,
        genreInput,
        releaseDateInput
    }, { persistence, resourceInputs, notes, artwork });
    editor.init();

    const galleryController = new GalleryController({
        gallery,
        gallerySection,
        galleryStatus,
        galleryTitle,
        notesOpenButton: notesGalleryOpen,
        galleryCloseButton: galleryClose
    }, {
        onSelectCover: (id, thumbnailUrl) => {
            artwork.setArtwork(id, thumbnailUrl);
        },
        onInsertMarkdown: (md) => {
            notes.insertMarkdown(md);
        }
    });
    galleryController.init();

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

    const previewButton = document.getElementById('editor-book-preview');
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
            let normalized = dateValue;
            if (/^\d{4}$/.test(dateValue)) {
                normalized = `${dateValue}-01-01`;
            } else {
                const dmy = dateValue.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/);
                if (dmy) {
                    normalized = `${dmy[3]}-${dmy[2].padStart(2, '0')}-${dmy[1].padStart(2, '0')}`;
                }
            }
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
