class SearchController {
    constructor({ openButton, form, input }) {
        this.openButton = openButton;
        this.form = form;
        this.input = input;
        this._onOpenClick = this.toggle.bind(this);
        this._onBlur = this._handleBlur.bind(this);
    }

    init() {
        this.openButton.addEventListener('click', this._onOpenClick);
        this.input.addEventListener('blur', this._onBlur);
        if (this.input.value) {
            this._open();
        }
    }

    destroy() {
        this.openButton.removeEventListener('click', this._onOpenClick);
        this.input.removeEventListener('blur', this._onBlur);
    }

    toggle() {
        if (this.form.classList.contains('open')) {
            this._close();
        } else {
            this._open();
        }
    }

    _open() {
        this.form.classList.add('open');
        this.openButton.classList.add('active');
        this.input.focus();
    }

    _close() {
        this.form.classList.remove('open');
        this.openButton.classList.remove('active');
    }

    _submit() {
        const params = new URLSearchParams(window.location.search);
        if (this.input.value) {
            params.set('term', this.input.value);
        } else {
            params.delete('term');
        }
        window.location.href = window.location.pathname + '?' + params.toString();
    }

    _handleBlur() {
        const originalTerm = new URLSearchParams(window.location.search).get('term') ?? '';
        if (this.input.value !== originalTerm) {
            this._submit();
        } else if (!this.input.value) {
            this._close();
        }
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const ctrl = new SearchController({
        openButton: document.getElementById('search-open'),
        form: document.getElementById('search-form'),
        input: document.getElementById('search-input'),
    });
    ctrl.init();
});
