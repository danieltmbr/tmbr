class SearchController {
    constructor({ openButton, input }) {
        this.openButton = openButton;
        this.input = input;
        this._onOpenClick = () => input.focus();
        this._onBlur = this._handleBlur.bind(this);
        this._onSubmit = this._handleSubmit.bind(this);
    }

    init() {
        this.openButton.addEventListener('click', this._onOpenClick);
        this.input.addEventListener('blur', this._onBlur);
        this.input.form?.addEventListener('submit', this._onSubmit);
    }

    destroy() {
        this.openButton.removeEventListener('click', this._onOpenClick);
        this.input.removeEventListener('blur', this._onBlur);
        this.input.form?.removeEventListener('submit', this._onSubmit);
    }

    _handleSubmit(e) {
        e.preventDefault();
        this._navigate();
    }

    _handleBlur() {
        const originalTerm = new URLSearchParams(window.location.search).get('term') ?? '';
        if (this.input.value !== originalTerm) {
            this._navigate();
        }
    }

    _navigate() {
        const params = new URLSearchParams(window.location.search);
        if (this.input.value) {
            params.set('term', this.input.value);
        } else {
            params.delete('term');
        }
        window.location.href = window.location.pathname + '?' + params.toString();
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const ctrl = new SearchController({
        openButton: document.getElementById('search-open'),
        input: document.getElementById('search-input'),
    });
    ctrl.init();
});
