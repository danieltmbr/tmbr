class NoteDetailController {

    constructor({ section }, { persistence }) {
        this.section = section;
        this.notesEndpoint = section.dataset.notesEndpoint;
        this.newWrapper = section.querySelector('.note-new');
        this.newTextarea = this.newWrapper?.querySelector('textarea');
        this.newToggle = this.newWrapper?.querySelector('.note-access-toggle');
        this.newLangSelect = this.newWrapper?.querySelector('.note-language-select');
        this.persistence = persistence;

        this._onNewWrapperFocusOut = this._onNewWrapperFocusOut.bind(this);
    }

    init() {
        this.section.querySelectorAll('article.note:has(.note-edit-area)').forEach(article => {
            this._setupNote(article);
            this._restorePendingEdit(article);
        });

        if (this.newWrapper) {
            this.newTextarea.addEventListener('input', () => this._autosize(this.newTextarea));
            this.newWrapper.querySelector('label.note-access')
                ?.addEventListener('mousedown', (e) => e.preventDefault());
            this.newWrapper.addEventListener('focusout', this._onNewWrapperFocusOut);
            this._restorePendingNew();
        }
    }

    destroy() {
        this.section.querySelectorAll('article.note:has(.note-edit-area)').forEach(article => {
            article.querySelector('button')?.removeEventListener('click', article._onEditClick);
            article.removeEventListener('focusout', article._onFocusOut);
        });
        this.newWrapper?.removeEventListener('focusout', this._onNewWrapperFocusOut);
    }

    // ── Setup ────────────────────────────────────────────────────────────────

    _setupNote(article) {
        const textarea = article.querySelector('textarea');
        const label = article.querySelector('label.note-access');

        const onEditClick = () => this._enterEditMode(article);
        article._onEditClick = onEditClick;
        article.querySelector('button')?.addEventListener('click', onEditClick);

        const onFocusOut = (e) => {
            if (!article.classList.contains('editing')) return;
            if (article.contains(e.relatedTarget)) return;
            const ta = article.querySelector('textarea');
            const toggle = article.querySelector('.note-access-toggle');
            this._saveNote(article, ta, toggle);
        };
        article._onFocusOut = onFocusOut;
        article.addEventListener('focusout', onFocusOut);

        textarea?.addEventListener('input', () => this._autosize(textarea));
        label?.addEventListener('mousedown', (e) => e.preventDefault());
    }

    // ── Edit mode ────────────────────────────────────────────────────────────

    _enterEditMode(article, initialBody = null, initialAccess = null, initialLanguage = null) {
        if (article.classList.contains('editing')) return;
        const textarea = article.querySelector('textarea');
        const toggle = article.querySelector('.note-access-toggle');
        const langSelect = article.querySelector('.note-language-select');
        if (!textarea) return;
        if (initialBody !== null) textarea.value = initialBody;
        if (initialAccess !== null && toggle) toggle.checked = initialAccess === 'public';
        if (initialLanguage !== null && langSelect) langSelect.value = initialLanguage;
        article.classList.add('editing');
        this._autosize(textarea);
        textarea.focus();
    }

    // ── Save existing note (web endpoint returns HTML fragment) ──────────────

    async _saveNote(article, textarea, toggle) {
        const noteID = article.dataset.noteId;
        const body = textarea?.value.trim() ?? '';
        const access = toggle?.checked ? 'public' : 'private';
        const language = article.querySelector('.note-language-select')?.value ?? 'en';
        const key = `detail:note:${noteID}`;

        const params = new URLSearchParams({ body, access, language });
        let res;
        try {
            res = await fetch(`/notes/${noteID}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: params
            });
        } catch {
            this.persistence.save(key, { body, access, language });
            this._showNetworkError(article);
            return;
        }

        this.persistence.clear(key);
        const html = await res.text();
        const newArticle = this._parseFragment(html);
        if (!newArticle) return;

        article.replaceWith(newArticle);
        this._setupNote(newArticle);

        if (!res.ok) {
            const ta = newArticle.querySelector('textarea');
            if (ta) { this._autosize(ta); ta.focus(); }
        } else {
            this._showSaved(newArticle);
        }
    }

    // ── Restore pending edit from localStorage ───────────────────────────────

    _restorePendingEdit(article) {
        const noteID = article.dataset.noteId;
        const key = `detail:note:${noteID}`;
        const pending = this.persistence.load(key);
        if (!pending) return;
        this._enterEditMode(article, pending.body, pending.access, pending.language ?? null);
        this._showUnsaved(article);
    }

    // ── New note ─────────────────────────────────────────────────────────────

    _onNewWrapperFocusOut(e) {
        if (this.newWrapper.contains(e.relatedTarget)) return;
        const body = this.newTextarea.value.trim();
        if (!body) return;
        const language = this.newLangSelect?.value ?? 'en';
        this._createNote(body, this.newToggle.checked, language);
    }

    async _createNote(body, isPublic, language = 'en') {
        const access = isPublic ? 'public' : 'private';
        const key = `detail:${this.notesEndpoint}:note:new`;

        const params = new URLSearchParams({ body, access, language });
        let res;
        try {
            res = await fetch(this.notesEndpoint, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: params
            });
        } catch {
            this.persistence.save(key, { body, access, language });
            this._showNetworkError(this.newWrapper);
            return;
        }

        if (!res.ok) {
            this.persistence.save(key, { body, access, language });
            this._showUnsaved(this.newWrapper);
            return;
        }

        this.persistence.clear(key);
        const html = await res.text();
        const newArticle = this._parseFragment(html);
        if (!newArticle) return;

        this.newWrapper.after(newArticle);
        this._setupNote(newArticle);
        this.newTextarea.value = '';
        this.newToggle.checked = false;
        if (this.newLangSelect) this.newLangSelect.value = 'en';
        this._autosize(this.newTextarea);
        this.newWrapper.classList.remove('note-unsaved');
        this._showSaved(newArticle);
    }

    _restorePendingNew() {
        const key = `detail:${this.notesEndpoint}:note:new`;
        const pending = this.persistence.load(key);
        if (!pending) return;
        this.newTextarea.value = pending.body;
        if (pending.access === 'public') this.newToggle.checked = true;
        if (pending.language && this.newLangSelect) this.newLangSelect.value = pending.language;
        this._autosize(this.newTextarea);
        this._showUnsaved(this.newWrapper);
    }

    // ── DOM helpers ──────────────────────────────────────────────────────────

    _parseFragment(html) {
        const temp = document.createElement('div');
        temp.innerHTML = html;
        return temp.firstElementChild ?? null;
    }

    _autosize(textarea) {
        textarea.style.height = 'auto';
        textarea.style.height = `${textarea.scrollHeight}px`;
    }

    // ── State indicators ─────────────────────────────────────────────────────

    _showSaved(el) {
        el.classList.add('note-saved');
        setTimeout(() => el.classList.remove('note-saved'), 1500);
    }

    _showUnsaved(el) {
        el.classList.add('note-unsaved');
    }

    _showNetworkError(el) {
        el.classList.add('note-unsaved');
        el.classList.add('note-network-error');
        setTimeout(() => el.classList.remove('note-network-error'), 3000);
    }
}
