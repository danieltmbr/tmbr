class NoteDetailController {

    constructor({ section }, { persistence }) {
        this.section = section;
        this.songID = section.dataset.songId;
        this.newWrapper = section.querySelector('.note-new');
        this.newTextarea = this.newWrapper?.querySelector('textarea');
        this.newToggle = this.newWrapper?.querySelector('.note-access-toggle');
        this.persistence = persistence;

        this._onNewWrapperFocusOut = this._onNewWrapperFocusOut.bind(this);
    }

    init() {
        // Only attach edit handlers to notes that have editDetails (owner viewing)
        this.section.querySelectorAll('article.note[data-raw-body]').forEach(article => {
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
        this.section.querySelectorAll('article.note[data-raw-body]').forEach(article => {
            article.querySelector('button')?.removeEventListener('click', article._onEditClick);
            article.removeEventListener('focusout', article._onFocusOut);
        });
        this.newWrapper?.removeEventListener('focusout', this._onNewWrapperFocusOut);
    }

    // ── Setup ────────────────────────────────────────────────────────────────

    _setupNote(article) {
        const onEditClick = () => this._enterEditMode(article);
        article._onEditClick = onEditClick;
        article.querySelector('button')?.addEventListener('click', onEditClick);

        const onFocusOut = (e) => {
            if (!article.classList.contains('editing')) return;
            if (article.contains(e.relatedTarget)) return;
            const textarea = article.querySelector('textarea');
            const toggle = article.querySelector('.note-access-toggle');
            this._saveNote(article, textarea, toggle);
        };
        article._onFocusOut = onFocusOut;
        article.addEventListener('focusout', onFocusOut);
    }

    // ── Edit mode ────────────────────────────────────────────────────────────

    _enterEditMode(article, initialBody = null, initialAccess = null) {
        if (article.classList.contains('editing')) return;

        const rawBody = initialBody ?? article.dataset.rawBody ?? '';
        const access = initialAccess ?? article.dataset.access ?? 'private';
        const noteBody = article.querySelector('.note-body');
        if (!noteBody) return;

        const textarea = document.createElement('textarea');
        textarea.value = rawBody;
        textarea.autocapitalize = 'sentences';
        textarea.spellcheck = true;
        textarea.addEventListener('input', () => this._autosize(textarea));

        const { hidden, label } = this._createAccessToggle(access === 'public');
        label.addEventListener('mousedown', (e) => e.preventDefault());

        const wrapper = document.createElement('div');
        wrapper.className = 'note-edit-area';
        wrapper.appendChild(textarea);
        wrapper.appendChild(hidden);
        wrapper.appendChild(label);

        article.dataset.htmlBody = noteBody.innerHTML;
        noteBody.replaceWith(wrapper);
        article.classList.add('editing');
        this._autosize(textarea);
        textarea.focus();
    }

    // ── Save existing note (web endpoint returns HTML fragment) ──────────────

    async _saveNote(article, textarea, toggle) {
        const noteID = article.dataset.noteId;
        const body = textarea?.value.trim() ?? '';
        const access = toggle?.checked ? 'public' : 'private';
        const key = `detail:note:${noteID}`;

        const params = new URLSearchParams({ body, access });
        let res;
        try {
            res = await fetch(`/notes/${noteID}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: params
            });
        } catch {
            this.persistence.save(key, { body, access });
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
            // Server returned edit mode with error — re-autosize, focus, wire mousedown
            const ta = newArticle.querySelector('textarea');
            if (ta) {
                this._autosize(ta);
                ta.focus();
                ta.addEventListener('input', () => this._autosize(ta));
            }
            newArticle.querySelector('label.note-access')
                ?.addEventListener('mousedown', (e) => e.preventDefault());
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
        this._enterEditMode(article, pending.body, pending.access);
        this._showUnsaved(article);
    }

    // ── New note ─────────────────────────────────────────────────────────────

    _onNewWrapperFocusOut(e) {
        if (this.newWrapper.contains(e.relatedTarget)) return;
        const body = this.newTextarea.value.trim();
        if (!body) return;
        this._createNote(body, this.newToggle.checked);
    }

    async _createNote(body, isPublic) {
        const access = isPublic ? 'public' : 'private';
        const key = `detail:song:${this.songID}:note:new`;

        const params = new URLSearchParams({ body, access });
        let res;
        try {
            res = await fetch(`/songs/${this.songID}/notes`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: params
            });
        } catch {
            this.persistence.save(key, { body, access });
            this._showNetworkError(this.newWrapper);
            return;
        }

        if (!res.ok) {
            this.persistence.save(key, { body, access });
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
        this._autosize(this.newTextarea);
        this.newWrapper.classList.remove('note-unsaved');
        this._showSaved(newArticle);
    }

    _restorePendingNew() {
        const key = `detail:song:${this.songID}:note:new`;
        const pending = this.persistence.load(key);
        if (!pending) return;
        this.newTextarea.value = pending.body;
        if (pending.access === 'public') this.newToggle.checked = true;
        this._autosize(this.newTextarea);
        this._showUnsaved(this.newWrapper);
    }

    // ── DOM helpers ──────────────────────────────────────────────────────────

    _parseFragment(html) {
        const temp = document.createElement('div');
        temp.innerHTML = html;
        return temp.firstElementChild ?? null;
    }

    _createAccessToggle(isPublic) {
        const hidden = document.createElement('input');
        hidden.type = 'hidden';
        hidden.className = 'note-access-fallback';
        hidden.value = 'private';

        const label = document.createElement('label');
        label.className = 'note-access';

        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.className = 'note-access-toggle';
        checkbox.value = 'public';
        checkbox.checked = isPublic;

        label.appendChild(checkbox);
        label.appendChild(document.createTextNode(' Public'));

        return { hidden, label };
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
