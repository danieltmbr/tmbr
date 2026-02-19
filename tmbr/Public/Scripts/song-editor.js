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

    markPendingClear(key) {
        try {
            localStorage.setItem(this.pendingKeyName, key);
        } catch (_) {
            // ignore
        }
    }

    clearPendingIfNavigatedAway() {
        try {
            const pending = localStorage.getItem(this.pendingKeyName);
            if (!pending) return;
            const stillOnEditor = !!document.getElementById('song-form');
            if (stillOnEditor) return;
            localStorage.removeItem(pending);
            localStorage.removeItem(this.pendingKeyName);
        } catch (_) {
            // ignore
        }
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
        input.className = 'resource-url';
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
        this.textareaListeners = [];
    }

    init() {
        this.getTextareas().forEach((textarea) => this.attachListener(textarea));
        this.autosizeAll();
    }

    destroy() {
        this.textareaListeners.forEach(({ textarea }) => {
            textarea.removeEventListener('input', this._onInput);
            textarea.removeEventListener('blur', this._onBlur);
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
        this.textareaListeners.push({ textarea });
    }

    detachListener(textarea) {
        textarea.removeEventListener('input', this._onInput);
        textarea.removeEventListener('blur', this._onBlur);
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

        // Add new textarea if all are filled
        if (textarea.value.trim() && emptyTextareas.length === 0) {
            const newTextarea = this.createTextarea();
            this.section.appendChild(newTextarea);
            this.attachListener(newTextarea);
        }
        // Remove empty textarea if there's more than one empty
        else if (!textarea.value.trim() && emptyTextareas.length > 1) {
            this.detachListener(textarea);
            textarea.remove();
        }
    }
}

class AutofillController {
    constructor({
        titleInput,
        artistInput,
        albumInput,
        releaseDateInput,
        statusEl
    }, { metadata }) {
        this.titleInput = titleInput;
        this.artistInput = artistInput;
        this.albumInput = albumInput;
        this.releaseDateInput = releaseDateInput;
        this.statusEl = statusEl;
        this.metadata = metadata;
    }

    async fetchAndApply(url) {
        try {
            const song = await this.metadata.fetch(url);
            this.applyMetadata(song);
            this.setStatus('');
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
        releaseDateInput,
        accessSelect
    }, { persistence, resourceInputs, notes }) {
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

        this.songID = this.idInput ? this.idInput.value : '';
        this.storageKey = this.songID ? `editor:song:${this.songID}` : 'editor:song:new';

        this._onSaveDraft = this.saveDraft.bind(this);
    }

    init() {
        this.loadDraft();

        // Save draft on any input change
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
        // For preview, join all notes with double newlines
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
            resourceURLs: this.resourceInputs.getValues()
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
    }

    saveDraft() {
        this.persistence.save(this.storageKey, this.getState());
    }

    loadDraft() {
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

    const idInput = document.getElementById('editor-song-id');
    const titleInput = document.getElementById('editor-song-title');
    const artistInput = document.getElementById('editor-song-artist');
    const albumInput = document.getElementById('editor-song-album');
    const genreInput = document.getElementById('editor-song-genre');
    const releaseDateInput = document.getElementById('editor-song-release-date');
    const releaseDateISOInput = document.getElementById('editor-song-release-date-iso');
    const accessSelect = document.getElementById('access');
    const resourcesSection = document.getElementById('resources-section');
    const notesSection = document.getElementById('notes-section');
    const statusEl = document.getElementById('autofill-status');

    const persistence = new PersistenceController();
    const metadata = new MetadataController();

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
    }, { metadata });

    const editor = new EditorController({
        form,
        idInput,
        titleInput,
        artistInput,
        albumInput,
        genreInput,
        releaseDateInput,
        accessSelect
    }, { persistence, resourceInputs, notes });
    editor.init();

    const shortcuts = new ShortcutsController({
        onPreview: () => editor.preview()
    });
    shortcuts.init();

    form.addEventListener('submit', () => {
        // Convert date to ISO 8601 format for the backend
        const dateValue = releaseDateInput.value;
        if (dateValue) {
            releaseDateISOInput.value = new Date(dateValue).toISOString();
        }
        persistence.markPendingClear(editor.getStorageKey());
    });
    window.addEventListener('pageshow', () => persistence.clearPendingIfNavigatedAway());
});
