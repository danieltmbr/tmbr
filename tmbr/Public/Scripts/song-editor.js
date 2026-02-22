class PersistenceController {
    constructor() {
        this.pendingKeyName = 'editor:pendingClear';
    }

    load(key) {
        try {
            const raw = localStorage.getItem(key);
            return raw ? JSON.parse(raw) : null;
        } catch (_) {
            return null;
        }
    }

    save(key, state) {
        try {
            localStorage.setItem(key, JSON.stringify(state));
        } catch (err) {
            console.error(`Couldn't save draft. ${err?.message || err}`);
        }
    }

    clear(key) {
        try {
            localStorage.removeItem(key);
        } catch (_) {
            // ignore
        }
    }

    clearIfPending(key) {
        try {
            const pending = localStorage.getItem(this.pendingKeyName);
            if (pending === key) {
                localStorage.removeItem(key);
                localStorage.removeItem(this.pendingKeyName);
                return true;
            }
            return false;
        } catch (_) {
            return false;
        }
    }

    markPendingClear(key) {
        try {
            localStorage.setItem(this.pendingKeyName, key);
        } catch (_) {
            // ignore
        }
    }
}

class UploadsController {
    async uploadImageFile(file) {
        const form = new FormData();
        form.append('image', file, file.name);
        form.append('alt', file.name.replace(/\.[^.]+$/, ''));
        const res = await fetch('/gallery', { method: 'POST', body: form });
        if (!res.ok) {
            const text = await res.text().catch(() => '');
            throw new Error(text || `Upload failed with status ${res.status}`);
        }
        return await res.text();
    }

    async uploadImageFromURL(url, alt) {
        const res = await fetch('/gallery/from-url', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ url, alt })
        });
        if (!res.ok) throw new Error(`Upload failed (${res.status})`);
        return await res.json();
    }
}

class MetadataController {
    constructor({ endpoint = "/songs/metadata" } = {}) {
        this.endpoint = endpoint;
    }

    async fetch(url) {
        if (!url || typeof url !== 'string') {
            throw new Error('A valid URL is required to fetch song metadata.');
        }
        const encoded = encodeURIComponent(url);
        const response = await window.fetch(`${this.endpoint}?url=${encoded}`);
        if (!response.ok) throw new Error(`Metadata fetch failed (${response.status})`);
        return await response.json();
    }
}

class ArtworkController {
    constructor({ hiddenInput, externalUrlInput, placeholder, imageEl, clearButton }, { onChange, onOpenGallery }) {
        this.hiddenInput = hiddenInput;
        this.externalUrlInput = externalUrlInput;
        this.placeholder = placeholder;
        this.imageEl = imageEl;
        this.clearButton = clearButton;
        this.onChange = onChange;
        this.onOpenGallery = onOpenGallery;
        this._onClear = this.clear.bind(this);
        this._onPlaceholderClick = this.onPlaceholderClick.bind(this);
    }

    init() {
        this.clearButton.addEventListener('click', this._onClear);
        this.placeholder.addEventListener('click', this._onPlaceholderClick);
    }

    destroy() {
        this.clearButton.removeEventListener('click', this._onClear);
        this.placeholder.removeEventListener('click', this._onPlaceholderClick);
    }

    onPlaceholderClick(e) {
        if (e.target === this.clearButton || this.clearButton.contains(e.target)) {
            return;
        }
        if (typeof this.onOpenGallery === 'function') {
            this.onOpenGallery();
        }
    }

    setArtwork(imageId, thumbnailUrl) {
        this.hiddenInput.value = imageId || '';
        this.externalUrlInput.value = '';
        this.imageEl.src = thumbnailUrl || '';
        this.placeholder.classList.toggle('empty', !imageId);
        if (typeof this.onChange === 'function') {
            this.onChange();
        }
    }

    setExternalURL(url) {
        this.hiddenInput.value = '';
        this.externalUrlInput.value = url || '';
        this.imageEl.src = url || '';
        this.placeholder.classList.toggle('empty', !url);
        if (typeof this.onChange === 'function') {
            this.onChange();
        }
    }

    clear(e) {
        if (e) e.stopPropagation();
        this.hiddenInput.value = '';
        this.externalUrlInput.value = '';
        this.imageEl.src = '';
        this.placeholder.classList.add('empty');
        if (typeof this.onChange === 'function') {
            this.onChange();
        }
    }

    getArtworkId() {
        const val = this.hiddenInput.value;
        return val ? parseInt(val, 10) : null;
    }

    getExternalURL() {
        return this.externalUrlInput.value || null;
    }

    getThumbnailUrl() {
        return this.imageEl.src || null;
    }

    isEmpty() {
        return !this.hiddenInput.value && !this.externalUrlInput.value;
    }

    hasExternalURL() {
        return !this.hiddenInput.value && !!this.externalUrlInput.value;
    }
}

class ResourceInputsController {
    constructor({ section }, { onUrlChange, onInput }) {
        this.section = section;
        this.onUrlChange = onUrlChange;
        this.onInputCallback = onInput;
        this._onInput = this.onInput.bind(this);
        this._onChange = this.onChange.bind(this);
        this._onPaste = this.onPaste.bind(this);
        this.inputListeners = [];
    }

    init() {
        this.getInputs().forEach((input) => this.attachListener(input));
    }

    destroy() {
        this.inputListeners.forEach(({ input }) => {
            input.removeEventListener('input', this._onInput);
            input.removeEventListener('change', this._onChange);
            input.removeEventListener('paste', this._onPaste);
        });
        this.inputListeners = [];
    }

    getInputs() {
        return Array.from(this.section.querySelectorAll('input.resource-url'));
    }

    getValues() {
        return this.getInputs()
            .map(input => input.value.trim())
            .filter(url => url.length > 0);
    }

    setValues(urls) {
        if (!Array.isArray(urls)) return;
        const inputs = this.getInputs();
        urls.forEach((url, index) => {
            if (inputs[index] && !inputs[index].value) {
                inputs[index].value = url;
            }
        });
    }

    attachListener(input) {
        input.addEventListener('input', this._onInput);
        input.addEventListener('change', this._onChange);
        input.addEventListener('paste', this._onPaste);
        this.inputListeners.push({ input });
    }

    detachListener(input) {
        input.removeEventListener('input', this._onInput);
        input.removeEventListener('change', this._onChange);
        input.removeEventListener('paste', this._onPaste);
        this.inputListeners = this.inputListeners.filter((entry) => entry.input !== input);
    }

    createInput() {
        const input = document.createElement('input');
        input.className = 'text-input resource-url';
        input.dataset.autofillSource = 'true';
        input.type = 'url';
        input.name = 'resourceURLs[]';
        input.value = '';
        input.placeholder = 'https://…';
        return input;
    }

    onInput(event) {
        const input = event.target;
        const inputs = this.getInputs();
        const emptyInputs = inputs.filter((i) => !i.value.trim());

        if (input.value.trim() && emptyInputs.length === 0) {
            const newInput = this.createInput();
            this.section.appendChild(newInput);
            this.attachListener(newInput);
        } else if (!input.value.trim() && emptyInputs.length > 1) {
            this.detachListener(input);
            input.remove();
        }

        if (typeof this.onInputCallback === 'function') {
            this.onInputCallback();
        }
    }

    onChange(event) {
        const url = (event.target.value || '').trim();
        if (url && typeof this.onUrlChange === 'function') {
            this.onUrlChange(url);
        }
    }

    onPaste(event) {
        setTimeout(() => {
            const url = (event.target.value || '').trim();
            if (url && typeof this.onUrlChange === 'function') {
                this.onUrlChange(url);
            }
        }, 0);
    }
}

class NotesController {
    constructor({ section }, { onInput }) {
        this.section = section;
        this.onInputCallback = onInput;
        this._onInput = this.onInput.bind(this);
        this._onBlur = this.onBlur.bind(this);
        this._onFocus = this.onFocus.bind(this);
        this.textareaListeners = [];
        this.lastFocusedTextarea = null;
    }

    init() {
        this.getTextareas().forEach((textarea) => this.attachListener(textarea));
        this.autosizeAll();
    }

    destroy() {
        this.textareaListeners.forEach(({ textarea }) => {
            textarea.removeEventListener('input', this._onInput);
            textarea.removeEventListener('blur', this._onBlur);
            textarea.removeEventListener('focus', this._onFocus);
        });
        this.textareaListeners = [];
    }

    getTextareas() {
        return Array.from(this.section.querySelectorAll('textarea.note-body'));
    }

    getValues() {
        return this.getTextareas()
            .map(textarea => textarea.value.trim())
            .filter(note => note.length > 0);
    }

    setValues(notes) {
        if (!Array.isArray(notes)) return;
        const textareas = this.getTextareas();
        notes.forEach((note, index) => {
            if (textareas[index] && !textareas[index].value) {
                textareas[index].value = note;
            }
        });
        this.autosizeAll();
    }

    attachListener(textarea) {
        textarea.addEventListener('input', this._onInput);
        textarea.addEventListener('blur', this._onBlur);
        textarea.addEventListener('focus', this._onFocus);
        this.textareaListeners.push({ textarea });
    }

    detachListener(textarea) {
        textarea.removeEventListener('input', this._onInput);
        textarea.removeEventListener('blur', this._onBlur);
        textarea.removeEventListener('focus', this._onFocus);
        this.textareaListeners = this.textareaListeners.filter((entry) => entry.textarea !== textarea);
    }

    createTextarea() {
        const textarea = document.createElement('textarea');
        textarea.className = 'note-body';
        textarea.name = 'notes[]';
        textarea.placeholder = 'Write your thoughts...';
        textarea.autocapitalize = 'sentences';
        textarea.spellcheck = true;
        return textarea;
    }

    autosize(textarea) {
        textarea.style.height = 'auto';
        textarea.style.height = textarea.scrollHeight + 'px';
    }

    autosizeAll() {
        this.getTextareas().forEach(textarea => this.autosize(textarea));
    }

    onFocus(event) {
        this.lastFocusedTextarea = event.target;
    }

    onInput(event) {
        const textarea = event.target;
        this.autosize(textarea);

        if (typeof this.onInputCallback === 'function') {
            this.onInputCallback();
        }
    }

    onBlur(event) {
        const textarea = event.target;
        const textareas = this.getTextareas();
        const emptyTextareas = textareas.filter((t) => !t.value.trim());

        if (textarea.value.trim() && emptyTextareas.length === 0) {
            const newTextarea = this.createTextarea();
            this.section.appendChild(newTextarea);
            this.attachListener(newTextarea);
        } else if (!textarea.value.trim() && emptyTextareas.length > 1) {
            this.detachListener(textarea);
            textarea.remove();
        }
    }

    insertMarkdown(markdown) {
        let target = this.lastFocusedTextarea;
        if (!target) {
            const textareas = this.getTextareas();
            target = textareas.find(t => t.value.trim()) || textareas[textareas.length - 1];
        }
        if (!target) return;

        const start = target.selectionStart ?? target.value.length;
        const end = target.selectionEnd ?? target.value.length;
        const before = target.value.slice(0, start);
        const after = target.value.slice(end);

        const prefix = (before && !before.endsWith('\n')) ? '\n' : '';
        const suffix = '\n';
        const insert = prefix + markdown + suffix;

        target.value = before + insert + after;
        const pos = before.length + insert.length;
        target.selectionStart = target.selectionEnd = pos;
        target.dispatchEvent(new Event('input', { bubbles: true }));
        this.autosize(target);
        target.focus();
    }
}

class AutofillController {
    constructor({
        titleInput,
        artistInput,
        albumInput,
        releaseDateInput,
        statusEl
    }, { metadata, artwork, onApply }) {
        this.titleInput = titleInput;
        this.artistInput = artistInput;
        this.albumInput = albumInput;
        this.releaseDateInput = releaseDateInput;
        this.statusEl = statusEl;
        this.metadata = metadata;
        this.artwork = artwork;
        this.onApply = onApply;
    }

    async fetchAndApply(url) {
        try {
            const song = await this.metadata.fetch(url);
            this.applyMetadata(song);
            this.setStatus('');
            if (typeof this.onApply === 'function') {
                this.onApply();
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

class GalleryController {
    constructor({
        gallery,
        gallerySection,
        galleryStatus,
        galleryTitle,
        notesOpenButton,
        galleryCloseButton
    }, { onSelectArtwork, onInsertMarkdown }) {
        this.gallery = gallery;
        this.gallerySection = gallerySection;
        this.galleryStatus = galleryStatus;
        this.galleryTitle = galleryTitle;
        this.notesOpenButton = notesOpenButton;
        this.galleryCloseButton = galleryCloseButton;
        this.onSelectArtwork = onSelectArtwork;
        this.onInsertMarkdown = onInsertMarkdown;
        this.mode = 'artwork';
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
        this.galleryTitle.textContent = mode === 'artwork' ? 'Select album artwork' : 'Insert into note';
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
                if (this.mode === 'artwork') {
                    if (typeof this.onSelectArtwork === 'function') {
                        this.onSelectArtwork(id, thumbnailUrl);
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
                    if (!item.type || item.type.startsWith('image/')) {
                        return true;
                    }
                }
            }
            return false;
        }

        if (dt.files && dt.files.length) {
            const files = Array.from(dt.files);
            if (files.every(f => f.type)) {
                return files.some(f => f.type.startsWith('image/'));
            }
            return true;
        }

        return true;
    }

    showCue() {
        document.body.classList.add('dragging-page');
        if (this.hideTimer) { clearTimeout(this.hideTimer); this.hideTimer = null; }
    }

    hideCueDebounced() {
        if (this.hideTimer) clearTimeout(this.hideTimer);
        this.hideTimer = setTimeout(() => {
            document.body.classList.remove('dragging-page');
        }, 60);
    }

    onDragEnter(e) {
        if (this.shouldShowCue(e)) {
            this.showCue();
        }
    }

    onDragOver(e) {
        e.preventDefault();
        if (this.shouldShowCue(e)) {
            this.showCue();
        } else {
            this.hideCueDebounced();
        }
    }

    onDragLeave() {
        this.hideCueDebounced();
    }

    getDropTarget(e) {
        const target = e.target;
        if (this.notesSection && this.notesSection.contains(target)) {
            return 'notes';
        }
        if (this.detailsSection && this.detailsSection.contains(target)) {
            return 'details';
        }
        if (this.resourcesSection && this.resourcesSection.contains(target)) {
            return 'details';
        }
        return 'details';
    }

    async onDrop(e) {
        e.preventDefault();
        document.body.classList.remove('dragging-page');
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
        artistInput,
        albumInput,
        genreInput,
        releaseDateInput,
        accessSelect
    }, { persistence, resourceInputs, notes, artwork }) {
        this.form = form;
        this.idInput = idInput;
        this.titleInput = titleInput;
        this.artistInput = artistInput;
        this.albumInput = albumInput;
        this.genreInput = genreInput;
        this.releaseDateInput = releaseDateInput;
        this.accessSelect = accessSelect;
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
        this.accessSelect.addEventListener('change', this._onSaveDraft);
    }

    destroy() {
        this.titleInput.removeEventListener('input', this._onSaveDraft);
        this.artistInput.removeEventListener('input', this._onSaveDraft);
        this.albumInput.removeEventListener('input', this._onSaveDraft);
        this.genreInput.removeEventListener('input', this._onSaveDraft);
        this.releaseDateInput.removeEventListener('input', this._onSaveDraft);
        this.accessSelect.removeEventListener('change', this._onSaveDraft);
    }

    getStorageKey() {
        return this.storageKey;
    }

    preview() {
        const previewForm = document.getElementById('preview-form');
        const previewTitleInput = document.getElementById('preview-title');
        const previewBodyInput = document.getElementById('preview-body');
        if (!previewForm || !previewTitleInput || !previewBodyInput) {
            alert('Preview form is missing from the template.');
            return;
        }
        const allNotes = this.notes.getValues().join('\n\n');
        previewTitleInput.value = this.titleInput.value || '';
        previewBodyInput.value = allNotes;
        previewForm.submit();
    }

    getState() {
        return {
            title: this.titleInput.value || '',
            artist: this.artistInput.value || '',
            album: this.albumInput.value || '',
            genre: this.genreInput.value || '',
            releaseDate: this.releaseDateInput.value || '',
            notes: this.notes.getValues(),
            access: this.accessSelect.value || 'private',
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
        if (typeof state.access === 'string') {
            this.accessSelect.value = state.access;
        }
        if (Array.isArray(state.notes)) {
            this.notes.setValues(state.notes);
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

class ShortcutsController {
    constructor({ onPreview }) {
        this.onPreview = onPreview;
        this._onKeyDown = this.onKeyDown.bind(this);
    }

    init() {
        document.addEventListener('keydown', this._onKeyDown);
    }

    destroy() {
        document.removeEventListener('keydown', this._onKeyDown);
    }

    onKeyDown(event) {
        const isMac = navigator.platform.toUpperCase().includes('MAC');
        const cmdOrCtrl = isMac ? event.metaKey : event.ctrlKey;
        const alt = event.altKey;
        const shift = event.shiftKey;
        const isPKey = event.code === 'KeyP';

        if (cmdOrCtrl && alt && !shift && isPKey && typeof this.onPreview === 'function') {
            event.preventDefault();
            this.onPreview();
        }
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('song-form');
    if (!form) return;

    const persistence = new PersistenceController();
    const uploads = new UploadsController();
    const metadata = new MetadataController();

    const idInput = document.getElementById('editor-song-id');
    const titleInput = document.getElementById('editor-song-title');
    const artistInput = document.getElementById('editor-song-artist');
    const albumInput = document.getElementById('editor-song-album');
    const genreInput = document.getElementById('editor-song-genre');
    const releaseDateInput = document.getElementById('editor-song-release-date');
    const releaseDateISOInput = document.getElementById('editor-song-release-date-iso');
    const accessSelect = document.getElementById('access');
    const resourcesSection = document.getElementById('resources-section');
    const detailsSection = document.getElementById('details-section');
    const notesSection = document.getElementById('notes-section');
    const statusEl = document.getElementById('autofill-status');

    const artworkIdInput = document.getElementById('editor-artwork-id');
    const artworkExternalUrlInput = document.getElementById('editor-artwork-external-url');
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
        externalUrlInput: artworkExternalUrlInput,
        placeholder: artworkPlaceholder,
        imageEl: artworkImage,
        clearButton: artworkClear
    }, {
        onChange: () => editor.saveDraft(),
        onOpenGallery: () => galleryController.open('artwork')
    });
    artwork.init();

    const notes = new NotesController(
        { section: notesSection },
        { onInput: () => editor.saveDraft() }
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

    const autofill = new AutofillController({
        titleInput,
        artistInput,
        albumInput,
        releaseDateInput,
        statusEl
    }, {
        metadata,
        artwork,
        onApply: () => editor.saveDraft()
    });

    const editor = new EditorController({
        form,
        idInput,
        titleInput,
        artistInput,
        albumInput,
        genreInput,
        releaseDateInput,
        accessSelect
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
        onSelectArtwork: (id, thumbnailUrl) => {
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

    const shortcuts = new ShortcutsController({
        onPreview: () => editor.preview()
    });
    shortcuts.init();

    async function resolveArtwork() {
        if (!artwork.hasExternalURL()) {
            return true;
        }

        const externalURL = artwork.getExternalURL();
        const titleValue = titleInput.value || 'Album artwork';

        statusEl.textContent = 'Resolving artwork...';
        statusEl.hidden = false;

        try {
            const lookupRes = await fetch(`/gallery/lookup?url=${encodeURIComponent(externalURL)}`);
            if (lookupRes.ok) {
                const existingImage = await lookupRes.json();
                if (existingImage && existingImage.id) {
                    artwork.setArtwork(existingImage.id, existingImage.thumbnailUrl);
                    statusEl.hidden = true;
                    return true;
                }
            }

            const image = await uploads.uploadImageFromURL(externalURL, titleValue);
            artwork.setArtwork(image.id, image.thumbnailUrl);
            statusEl.hidden = true;
            return true;
        } catch (err) {
            console.error(`Artwork resolution failed: ${err?.message || err}`);
            statusEl.textContent = 'Failed to resolve artwork. Submitting without it.';
            artwork.clear();
            return true;
        }
    }

    form.addEventListener('submit', async (e) => {
        e.preventDefault();

        const dateValue = releaseDateInput.value;
        if (dateValue) {
            releaseDateISOInput.value = new Date(dateValue).toISOString();
        }

        await resolveArtwork();

        persistence.markPendingClear(editor.getStorageKey());
        form.submit();
    });
});
