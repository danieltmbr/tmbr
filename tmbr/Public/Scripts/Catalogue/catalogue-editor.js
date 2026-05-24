class MetadataController {
    constructor({ endpoint } = {}) {
        this.endpoint = endpoint;
    }

    async fetch(url) {
        if (!url || typeof url !== 'string') {
            throw new Error('A valid URL is required to fetch metadata.');
        }
        const encoded = encodeURIComponent(url);
        const response = await window.fetch(`${this.endpoint}?url=${encoded}`);
        if (response.status === 401) {
            const err = new Error('Unauthorized');
            err.status = 401;
            throw err;
        }
        if (!response.ok) throw new Error(`Metadata fetch failed (${response.status})`);
        return await response.json();
    }
}

class LookupController {
    constructor({ endpoint, excludeID = null } = {}) {
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
    constructor({ containerEl, linkSelector }, { onNavigate } = {}) {
        this.containerEl = containerEl;
        this.linkSelector = linkSelector;
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
        this.linkEl = this.containerEl.querySelector(this.linkSelector);
        this._onDismiss = () => this.dialogEl?.close();
        this.dismissEl?.addEventListener('click', this._onDismiss);
        this.linkEl?.addEventListener('click', this._onNavigate);
        this.dialogEl?.showModal();
    }
}

class ImagePickerController {
    constructor({
        gallery,
        gallerySection,
        galleryStatus,
        galleryTitle,
        notesOpenButton,
        galleryCloseButton
    }, { onSelectImage, onInsertMarkdown, imageTitle = 'Select image' }) {
        this.gallery = gallery;
        this.gallerySection = gallerySection;
        this.galleryStatus = galleryStatus;
        this.galleryTitle = galleryTitle;
        this.notesOpenButton = notesOpenButton;
        this.galleryCloseButton = galleryCloseButton;
        this.onSelectImage = onSelectImage;
        this.onInsertMarkdown = onInsertMarkdown;
        this.imageTitle = imageTitle;
        this.mode = 'image';
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
        this.galleryTitle.textContent = mode === 'image' ? this.imageTitle : 'Insert into note';
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
                if (this.mode === 'image') {
                    if (typeof this.onSelectImage === 'function') {
                        this.onSelectImage(id, thumbnailUrl);
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
        if (this.shouldShowCue(e)) {
            this.showCue(this.getDropTarget(e));
        }
    }

    onDragOver(e) {
        e.preventDefault();
        if (this.shouldShowCue(e)) {
            this.showCue(this.getDropTarget(e));
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
        urls.forEach((url, index) => {
            const inputs = this.getInputs();
            if (inputs[index]) {
                if (!inputs[index].value) inputs[index].value = url;
            } else {
                const newInput = this.createInput();
                newInput.value = url;
                this.section.appendChild(newInput);
                this.attachListener(newInput);
            }
        });
        if (!this.getInputs().some(i => !i.value.trim())) {
            const newInput = this.createInput();
            this.section.appendChild(newInput);
            this.attachListener(newInput);
        }
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

function handleAutofillError(err, url, statusEl) {
    if (err.status === 401) {
        if (statusEl) {
            statusEl.textContent = '';
            statusEl.append(
                'Session expired. ',
                Object.assign(document.createElement('a'), {
                    href: '/signin?redirectReturn=' + encodeURIComponent(window.location.href),
                    textContent: 'Log in'
                }),
                ' to fetch metadata.'
            );
            statusEl.hidden = false;
        }
        sessionStorage.setItem('pendingMetadataURL', url);
    } else {
        if (statusEl) { statusEl.textContent = 'Failed to fetch metadata.'; statusEl.hidden = false; }
    }
}

function retryPendingMetadata(autofill) {
    const url = sessionStorage.getItem('pendingMetadataURL');
    if (url) {
        sessionStorage.removeItem('pendingMetadataURL');
        autofill.fetchAndApply(url);
    }
}
