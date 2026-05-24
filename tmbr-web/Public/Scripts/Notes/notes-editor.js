class NotesController {
    constructor({ section }, { onInput, onAccessChange }) {
        this.section = section;
        this.onInputCallback = onInput;
        this.onAccessChangeCallback = onAccessChange;
        this._onInput = this.onInput.bind(this);
        this._onBlur = this.onBlur.bind(this);
        this._onFocus = this.onFocus.bind(this);
        this._onAccessChange = this.onAccessChange.bind(this);
        this._onEditorActionsMousedown = this.onEditorActionsMousedown.bind(this);
        this.wrapperListeners = [];
        this.lastFocusedTextarea = null;
        this.nextIndex = parseInt(this.section.dataset.noteCount || '0', 10);
        this.suppressBlur = false;
    }

    init() {
        this.getWrappers().forEach((wrapper) => this.attachListener(wrapper));
        if (!this.getWrappers().some(w => !w.querySelector('textarea.note-body')?.value.trim())) {
            const empty = this.createWrapper(true);
            this.section.appendChild(empty);
            this.attachListener(empty);
        }
        this.autosizeAll();

        const editorActions = document.querySelector('.editor-actions');
        if (editorActions) {
            editorActions.addEventListener('mousedown', this._onEditorActionsMousedown);
        }
    }

    toggleDeleted(wrapper) {
        if (wrapper.classList.contains('deleted')) {
            wrapper.classList.remove('deleted');
            wrapper.querySelector('.note-deleted-flag')?.remove();
            wrapper.querySelector('.note-toggle')?.setAttribute('aria-label', 'Delete note');
        } else {
            const index = wrapper.dataset.index;
            wrapper.classList.add('deleted');
            const flag = document.createElement('input');
            flag.type = 'hidden';
            flag.name = `notes[${index}][deleted]`;
            flag.value = '1';
            flag.className = 'note-deleted-flag';
            wrapper.appendChild(flag);
            wrapper.querySelector('.note-toggle')?.setAttribute('aria-label', 'Restore note');
        }
    }

    destroy() {
        this.wrapperListeners.forEach(({ textarea, accessCheckbox, toggleBtn, onToggle }) => {
            if (textarea) {
                textarea.removeEventListener('input', this._onInput);
                textarea.removeEventListener('blur', this._onBlur);
                textarea.removeEventListener('focus', this._onFocus);
            }
            if (accessCheckbox) {
                accessCheckbox.removeEventListener('change', this._onAccessChange);
            }
            if (toggleBtn && onToggle) {
                toggleBtn.removeEventListener('click', onToggle);
            }
        });
        this.wrapperListeners = [];

        const editorActions = document.querySelector('.editor-actions');
        if (editorActions) {
            editorActions.removeEventListener('mousedown', this._onEditorActionsMousedown);
        }
    }

    getWrappers() {
        return Array.from(this.section.querySelectorAll('.note-wrapper'));
    }

    getTextareas() {
        return Array.from(this.section.querySelectorAll('textarea.note-body'));
    }

    getNotes() {
        return this.getWrappers()
            .map(wrapper => {
                const textarea = wrapper.querySelector('textarea.note-body');
                const checkbox = wrapper.querySelector('.note-access input[type="checkbox"]');
                const body = textarea ? textarea.value.trim() : '';
                const access = checkbox && checkbox.checked ? 'public' : 'private';
                return { body, access };
            })
            .filter(note => note.body.length > 0);
    }

    getValues() {
        return this.getNotes().map(n => n.body);
    }

    getAccessValues() {
        return this.getNotes().map(n => n.access);
    }

    setNotes(notes, isPublic) {
        if (!Array.isArray(notes)) return;
        notes.forEach((note, index) => {
            let wrapper = this.getWrappers()[index];
            if (!wrapper) {
                wrapper = this.createWrapper(isPublic);
                this.section.appendChild(wrapper);
                this.attachListener(wrapper);
            }
            const textarea = wrapper.querySelector('textarea.note-body');
            const checkbox = wrapper.querySelector('.note-access input[type="checkbox"]');
            if (textarea && !textarea.value) {
                textarea.value = typeof note === 'string' ? note : (note.body || '');
            }
            if (checkbox) {
                checkbox.disabled = !isPublic;
                if (typeof note === 'object' && note.access) {
                    checkbox.checked = note.access === 'public' && isPublic;
                }
            }
        });
        const hasEmpty = this.getWrappers().some(w => {
            const ta = w.querySelector('textarea.note-body');
            return ta && !ta.value.trim();
        });
        if (!hasEmpty) {
            const wrapper = this.createWrapper(isPublic);
            this.section.appendChild(wrapper);
            this.attachListener(wrapper);
        }
        this.autosizeAll();
    }

    setValues(notes) {
        this.setNotes(notes, true);
    }

    setAccessValues(accessValues, isPublic) {
        if (!Array.isArray(accessValues)) return;
        const wrappers = this.getWrappers();
        wrappers.forEach((wrapper, index) => {
            const checkbox = wrapper.querySelector('.note-access input[type="checkbox"]');
            if (checkbox) {
                checkbox.disabled = !isPublic;
                if (accessValues[index] !== undefined) {
                    checkbox.checked = accessValues[index] === 'public' && isPublic;
                }
            }
        });
    }

    setParentAccess(isPublic) {
        this.getWrappers().forEach(wrapper => {
            const checkbox = wrapper.querySelector('.note-access input[type="checkbox"]');
            if (checkbox) {
                checkbox.disabled = !isPublic;
                if (!isPublic) {
                    checkbox.checked = false;
                }
            }
        });
    }

    attachListener(wrapper) {
        const textarea = wrapper.querySelector('textarea.note-body');
        const accessCheckbox = wrapper.querySelector('.note-access input[type="checkbox"]');
        const toggleBtn = wrapper.querySelector('.note-toggle');
        const onToggle = toggleBtn ? () => this.toggleDeleted(wrapper) : null;

        if (textarea) {
            textarea.addEventListener('input', this._onInput);
            textarea.addEventListener('blur', this._onBlur);
            textarea.addEventListener('focus', this._onFocus);
        }
        if (accessCheckbox) {
            accessCheckbox.addEventListener('change', this._onAccessChange);
        }
        if (toggleBtn && onToggle) {
            toggleBtn.addEventListener('click', onToggle);
        }
        this.wrapperListeners.push({ wrapper, textarea, accessCheckbox, toggleBtn, onToggle });
    }

    detachListener(wrapper) {
        const entry = this.wrapperListeners.find(e => e.wrapper === wrapper);
        if (entry) {
            if (entry.textarea) {
                entry.textarea.removeEventListener('input', this._onInput);
                entry.textarea.removeEventListener('blur', this._onBlur);
                entry.textarea.removeEventListener('focus', this._onFocus);
            }
            if (entry.accessCheckbox) {
                entry.accessCheckbox.removeEventListener('change', this._onAccessChange);
            }
            if (entry.toggleBtn && entry.onToggle) {
                entry.toggleBtn.removeEventListener('click', entry.onToggle);
            }
        }
        this.wrapperListeners = this.wrapperListeners.filter(e => e.wrapper !== wrapper);
    }

    createWrapper(isPublic) {
        const index = this.nextIndex++;
        const template = this.section.querySelector('#note-wrapper-template');
        const wrapper = template.content.cloneNode(true).firstElementChild;

        wrapper.dataset.index = index;
        wrapper.querySelectorAll('[name]').forEach(el => {
            el.name = el.name.replace('notes[0]', `notes[${index}]`);
        });

        const checkbox = wrapper.querySelector('.note-access input[type="checkbox"]');
        if (checkbox) checkbox.disabled = !isPublic;

        return wrapper;
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

    onAccessChange() {
        if (typeof this.onAccessChangeCallback === 'function') {
            this.onAccessChangeCallback();
        }
    }

    onEditorActionsMousedown() {
        this.suppressBlur = true;
        setTimeout(() => { this.suppressBlur = false; }, 100);
    }

    onBlur(event) {
        const textarea = event.target;
        const wrapper = textarea.closest('.note-wrapper');

        if (this.suppressBlur) {
            setTimeout(() => this.manageWrappers(textarea, wrapper), 150);
            return;
        }

        this.manageWrappers(textarea, wrapper);
    }

    manageWrappers(textarea, wrapper) {
        const wrappers = this.getWrappers().filter(w => !w.classList.contains('deleted'));
        const emptyWrappers = wrappers.filter(w => {
            const ta = w.querySelector('textarea.note-body');
            return ta && !ta.value.trim();
        });

        if (textarea.value.trim() && emptyWrappers.length === 0) {
            const newWrapper = this.createWrapper(true);
            this.section.appendChild(newWrapper);
            this.attachListener(newWrapper);
        } else if (!textarea.value.trim() && emptyWrappers.length > 1 && wrapper && wrapper.parentNode) {
            this.detachListener(wrapper);
            wrapper.remove();
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
