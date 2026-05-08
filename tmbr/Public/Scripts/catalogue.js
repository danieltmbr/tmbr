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
        this.input.focus();
    }

    _close() {
        this.form.classList.remove('open');
    }

    _handleBlur() {
        if (!this.input.value) {
            this._close();
        }
    }
}

class FilterController {
    constructor({ openButton, closeButton, panel }) {
        this.openButton = openButton;
        this.closeButton = closeButton;
        this.panel = panel;
        this._onOpenClick = this.open.bind(this);
        this._onCloseClick = this.close.bind(this);
        this._onItemClick = this._handleItemClick.bind(this);
        this._onSelectAll = this._selectAll.bind(this);
        this._onDeselectAll = this._deselectAll.bind(this);
        this._onApply = this._apply.bind(this);
    }

    init() {
        this.openButton.addEventListener('click', this._onOpenClick);
        this.closeButton.addEventListener('click', this._onCloseClick);

        this.panel.querySelectorAll('.filter-item').forEach(item => {
            if (item.dataset.active !== 'true') {
                item.classList.add('inactive');
            }
            item.addEventListener('click', this._onItemClick);
        });

        document.getElementById('catalogue-filter-select-all')
            ?.addEventListener('click', this._onSelectAll);
        document.getElementById('catalogue-filter-deselect-all')
            ?.addEventListener('click', this._onDeselectAll);
        document.getElementById('catalogue-filter-apply')
            ?.addEventListener('click', this._onApply);
    }

    destroy() {
        this.openButton.removeEventListener('click', this._onOpenClick);
        this.closeButton.removeEventListener('click', this._onCloseClick);
        this.panel.querySelectorAll('.filter-item').forEach(item => {
            item.removeEventListener('click', this._onItemClick);
        });
    }

    open() {
        this.panel.classList.add('open');
    }

    close() {
        this.panel.classList.remove('open');
    }

    _handleItemClick(e) {
        e.currentTarget.classList.toggle('inactive');
    }

    _selectAll() {
        this.panel.querySelectorAll('.filter-item').forEach(item => {
            item.classList.remove('inactive');
        });
    }

    _deselectAll() {
        this.panel.querySelectorAll('.filter-item').forEach(item => {
            item.classList.add('inactive');
        });
    }

    _apply() {
        const params = new URLSearchParams();
        const searchInput = document.getElementById('catalogue-search-input');
        if (searchInput?.value) {
            params.set('term', searchInput.value);
        }
        this.panel.querySelectorAll('.filter-item:not(.inactive)').forEach(item => {
            if (item.dataset.type) params.append('types', item.dataset.type);
        });
        window.location.href = '/catalogue?' + params.toString();
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const searchController = new SearchController({
        openButton: document.getElementById('catalogue-search-open'),
        form: document.getElementById('catalogue-search'),
        input: document.getElementById('catalogue-search-input'),
    });
    searchController.init();

    const filterController = new FilterController({
        openButton: document.getElementById('catalogue-filter-open'),
        closeButton: document.getElementById('catalogue-filter-close'),
        panel: document.getElementById('catalogue-filter-panel'),
    });
    filterController.init();
});
