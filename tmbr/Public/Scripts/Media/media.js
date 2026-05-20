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
