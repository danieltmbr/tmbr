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
            const stillOnEditor = !!document.getElementById('post-form');
            if (stillOnEditor) return;
            localStorage.removeItem(pending);
            localStorage.removeItem(this.pendingKeyName);
        } catch (_) {
            // ignore
        }
    }
}

class Uploads {
    static async uploadImageFile(file) {
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
}

class EditorController {
    constructor({ form, idInput, titleInput, bodyTextArea, publishedCheckbox, previewButton }, { persistence }) {
        this.form = form;
        this.idInput = idInput;
        this.titleInput = titleInput;
        this.bodyTextArea = bodyTextArea;
        this.publishedCheckbox = publishedCheckbox;
        this.previewButton = previewButton;
        this.postID = this.idInput ? this.idInput.value : '';
        this.storageKey = this.postID ? `editor:post:${this.postID}` : 'editor:post:new';
        this._onAutosize = this.autosize.bind(this);
        this._onSaveDraft = this.saveDraft.bind(this);
        this._onPublishedChange = this.onPublishedChange.bind(this);
        this._onPreviewClick = this.preview.bind(this);
        this.persistence = persistence;
    }

    init() {
        this.loadDraft();
        this.previewButton.addEventListener('click', this._onPreviewClick);
        this.bodyTextArea.addEventListener('input', this._onAutosize);
        window.addEventListener('load', this._onAutosize);
        this.titleInput.addEventListener('input', this._onSaveDraft);
        this.bodyTextArea.addEventListener('input', this._onSaveDraft);
        this.publishedCheckbox.addEventListener('change', this._onPublishedChange);
        // Initial autosize pass
        this.autosize();
    }

    destroy() {
        this.previewButton.removeEventListener('click', this._onPreviewClick);
        this.bodyTextArea.removeEventListener('input', this._onAutosize);
        window.removeEventListener('load', this._onAutosize);
        this.titleInput.removeEventListener('input', this._onSaveDraft);
        this.bodyTextArea.removeEventListener('input', this._onSaveDraft);
        this.publishedCheckbox.removeEventListener('change', this._onPublishedChange);
    }

    getStorageKey() {
        return this.storageKey;
    }

    autosize() {
        const ta = this.bodyTextArea;
        ta.style.height = 'auto';
        ta.style.height = ta.scrollHeight + 'px';
    }

    ensureNewlineWrapped(text) {
        const ta = this.bodyTextArea;
        const prefix = (ta.value && !ta.value.endsWith('\n')) ? '\n' : '';
        return prefix + text + '\n';
    }

    insertAtCaret(text) {
        const textarea = this.bodyTextArea;
        const start = (typeof textarea.selectionStart === 'number') ? textarea.selectionStart : textarea.value.length;
        const end = (typeof textarea.selectionEnd === 'number') ? textarea.selectionEnd : textarea.value.length;
        const before = textarea.value.slice(0, start);
        const after = textarea.value.slice(end);
        const insert = this.ensureNewlineWrapped(text);
        textarea.value = before + insert + after;
        const pos = before.length + text.length;
        textarea.selectionStart = textarea.selectionEnd = pos;
        textarea.dispatchEvent(new Event('input', { bubbles: true }));
        this.autosize();
    }

    replacePlaceholder(placeholder, content) {
        const textarea = this.bodyTextArea;
        const idx = textarea.value.indexOf(placeholder);
        if (idx !== -1) {
            textarea.value = textarea.value.slice(0, idx) + content + textarea.value.slice(idx + placeholder.length);
            textarea.dispatchEvent(new Event('input', { bubbles: true }));
            this.autosize();
        }
    }

    focus() {
        const textarea = this.bodyTextArea;
        if (document.activeElement !== textarea) {
            textarea.focus();
            if (typeof textarea.selectionStart !== 'number' || typeof textarea.selectionEnd !== 'number') {
                const end = textarea.value.length;
                textarea.selectionStart = textarea.selectionEnd = end;
            }
        }
    }

    preview() {
        const previewForm = document.getElementById('preview-form');
        const previewTitleInput = document.getElementById('preview-title');
        const previewBodyInput = document.getElementById('preview-body');
        if (!previewForm || !previewTitleInput || !previewBodyInput) {
            alert('Preview form is missing from the template.');
            return;
        }
        previewTitleInput.value = this.titleInput.value || '';
        previewBodyInput.value = this.bodyTextArea.value || '';
        previewForm.submit();
    }

    getState() {
        return {
            title: this.titleInput.value || '',
            body: this.bodyTextArea.value || '',
            published: !!this.publishedCheckbox.checked,
        };
    }

    setState(state) {
        if (!state || typeof state !== 'object') return;
        if (typeof state.title === 'string' && !this.titleInput.value) {
            this.titleInput.value = state.title;
        }
        if (typeof state.body === 'string' && !this.bodyTextArea.value) {
            this.bodyTextArea.value = state.body;
        }
        if (typeof state.published === 'boolean') {
            this.publishedCheckbox.checked = state.published;
        }
    }

    saveDraft() {
        this.persistence.save(this.storageKey, this.getState());
    }

    loadDraft() {
        const saved = this.persistence.load(this.storageKey);
        if (saved) this.setState(saved);
    }

    onPublishedChange(e) {
        if (this.postID && !e.target.checked) {
            const ok = confirm('Unpublish this post? It will no longer be publicly visible.');
            if (!ok) {
                e.target.checked = true;
                return;
            }
        }
        this.saveDraft();
    }
}

class DragAndDropController {
    constructor({ editor, upload = Uploads.uploadImageFile }) {
        this.editor = editor;
        this.upload = upload;
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
        if (!dt) { return false; }

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

    async onDrop(e) {
        e.preventDefault();
        document.body.classList.remove('dragging-page');
        const dt = e.dataTransfer;
        if (!dt) return;

        const customMarkdown = dt.getData('application/x-editor-markdown') || '';
        if (customMarkdown) {
            this.editor.focus();
            this.editor.insertAtCaret(customMarkdown);
            return;
        }

        const files = Array.from(dt.files || []);
        if (!files.length) return;

        this.editor.focus();

        const imageFiles = files.filter(f => f && (!f.type || f.type.startsWith('image/')));
        if (!imageFiles.length) return;

        const entries = imageFiles.map((file) => {
            const filename = file.name;
            const placeholder = `![Uploading...](${filename})`;
            this.editor.insertAtCaret(placeholder);
            return { file, filename, placeholder };
        });

        const uploads = entries.map(async ({ file, filename, placeholder }) => {
            try {
                const markdown = await this.upload(file);
                this.editor.replacePlaceholder(placeholder, markdown);
                return { filename, ok: true };
            } catch (err) {
                const failed = `![Failed...](${filename})`;
                this.editor.replacePlaceholder(placeholder, failed);
                console.error(`Image upload failed: ${err?.message || err}`);
                return { filename, ok: false };
            }
        });

        await Promise.allSettled(uploads);
    }
}

class GalleryController {
    constructor({ gallery, galleryButton, onInsertMarkdown }) {
        this.gallery = gallery;
        this.galleryButton = galleryButton;
        this.onInsertMarkdown = onInsertMarkdown;
        this._onOpenClick = this.open.bind(this);
        this._onCloseEvent = this.close.bind(this);
        this._onEditorInsertEvent = this.onEditorInsertEvent.bind(this);
    }

    init() {
        this.galleryButton.addEventListener('click', this._onOpenClick);
        window.addEventListener('gallery-close', this._onCloseEvent);
        window.addEventListener('editor-insert-markdown', this._onEditorInsertEvent);
    }

    destroy() {
        this.galleryButton.removeEventListener('click', this._onOpenClick);
        window.removeEventListener('gallery-close', this._onCloseEvent);
        window.removeEventListener('editor-insert-markdown', this._onEditorInsertEvent);
    }

    async open() {
        this.gallery.style.display = 'block';
        this.gallery.innerHTML = 'Loading...';
        try {
            const res = await fetch('/gallery?embedded=true', { headers: { 'Accept': 'text/html' }});
            const html = await res.text();
            this.gallery.innerHTML = html;
            this.attachListenersToGallery();
        } catch (err) {
            this.gallery.innerHTML = 'Failed to load gallery.';
            console.error(`Image upload failed: ${err?.message || err}`);
        }
    }

    close() {
        this.gallery.style.display = 'none';
    }

    onEditorInsertEvent(e) {
        const md = e.detail && e.detail.markdown ? e.detail.markdown : '';
        if (!md) return;
        if (typeof this.onInsertMarkdown === 'function') {
            this.onInsertMarkdown(md);
        }
    }

    attachListenersToGallery() {
        const gallerySection = document.getElementById('gallery-section');
        const galleryItems = gallerySection.querySelectorAll('.gallery-item');
        const galleryCloseButton = document.getElementById('gallery-close');

        galleryCloseButton.addEventListener('click', () => {
            window.dispatchEvent(new CustomEvent('gallery-close'));
        });

        galleryItems.forEach((btn) => {
            const alt = btn.dataset.alt || '';
            const url = btn.dataset.url;
            if (!url) return;
            
            const markdown = `![${alt}](${url})`;
            
            btn.addEventListener('click', () => {
                let insert = new CustomEvent('editor-insert-markdown', { detail: { markdown } });
                window.dispatchEvent(insert);
            });
            
            btn.addEventListener('dragstart', (e) => {
                e.dataTransfer.setData('text/uri-list', url);
                e.dataTransfer.setData('text/plain', url);
                e.dataTransfer.setData('text/html', `<img src="${url}" alt="${alt}">`);
                e.dataTransfer.setData('application/x-editor-markdown', markdown);
                e.dataTransfer.effectAllowed = 'copy';
            });
        });
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

    isInputLike(el) {
        if (!el) return false;
        const tag = el.tagName;
        const editable = el.isContentEditable;
        return editable || tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT';
    }

    onKeyDown(event) {
        try {
            const active = document.activeElement;
            if (this.isInputLike(active)) { return; }
            const isMac = navigator.platform.toUpperCase().includes('MAC');
            const cmdOrCtrl = isMac ? event.metaKey : event.ctrlKey;
            const alt = event.altKey;
            const shift = event.shiftKey;
            const isPKey = event.code === 'KeyP';
            if (cmdOrCtrl && alt && !shift && isPKey) {
                event.preventDefault();
                if (typeof this.onPreview === 'function') this.onPreview();
            }
        } catch (_) {
            // ignore
        }
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('post-form');
    const idInput = document.getElementById('editor-post-id');
    const titleInput = document.getElementById('editor-post-title');
    const bodyTextArea = document.getElementById('editor-post-body');
    const publishedCheckbox = document.getElementById('editor-post-published');
    const previewButton = document.getElementById('editor-post-preview');
    const gallery = document.getElementById('gallery');
    const galleryButton = document.getElementById('gallery-open');

    const persistence = new PersistenceController();

    const editor = new EditorController({
        form,
        idInput,
        titleInput,
        bodyTextArea,
        publishedCheckbox,
        previewButton,
    }, { persistence });
    editor.init();

    const dnd = new DragAndDropController({ editor });
    dnd.init();

    const galleryController = new GalleryController({
        gallery,
        galleryButton,
        onInsertMarkdown: (md) => editor.insertAtCaret(md),
    });
    galleryController.init();

    const shortcuts = new ShortcutsController({ onPreview: () => editor.preview() });
    shortcuts.init();

    form.addEventListener('submit', () => persistence.markPendingClear(editor.getStorageKey()));
    window.addEventListener('pageshow', () => persistence.clearPendingIfNavigatedAway());
});
