class FilterController {
    constructor({ openButton, closeButton, panel }) {
        this.openButton = openButton;
        this.closeButton = closeButton;
        this.panel = panel;
        this._snapshot = new Set();
        this._onOpenClick = this.open.bind(this);
        this._onCloseClick = this.close.bind(this);
        this._onSelectAll = this._selectAll.bind(this);
        this._onDeselectAll = this._deselectAll.bind(this);
        this._onOutsideClick = this._handleOutsideClick.bind(this);
    }

    init() {
        this.openButton.addEventListener('click', this._onOpenClick);
        this.closeButton?.addEventListener('click', this._onCloseClick);

        document.getElementById('filter-select-all')
            ?.addEventListener('click', this._onSelectAll);
        document.getElementById('filter-deselect-all')
            ?.addEventListener('click', this._onDeselectAll);
    }

    destroy() {
        this.openButton.removeEventListener('click', this._onOpenClick);
        this.closeButton?.removeEventListener('click', this._onCloseClick);
        document.removeEventListener('click', this._onOutsideClick);
    }

    open() {
        this.panel.classList.add('open');
        this._snapshot = this._checkedValues();
        setTimeout(() => {
            document.addEventListener('click', this._onOutsideClick);
        }, 0);
    }

    close() {
        this.panel.classList.remove('open');
        document.removeEventListener('click', this._onOutsideClick);
        if (!this._matchesSnapshot()) {
            this._apply();
        }
    }

    _checkedValues() {
        const values = new Set();
        this.panel.querySelectorAll('input[type="checkbox"]:checked').forEach(cb => {
            values.add(cb.value);
        });
        return values;
    }

    _matchesSnapshot() {
        const current = this._checkedValues();
        if (current.size !== this._snapshot.size) return false;
        for (const v of current) {
            if (!this._snapshot.has(v)) return false;
        }
        return true;
    }

    _selectAll() {
        this.panel.querySelectorAll('input[type="checkbox"]').forEach(cb => {
            cb.checked = true;
        });
    }

    _deselectAll() {
        this.panel.querySelectorAll('input[type="checkbox"]').forEach(cb => {
            cb.checked = false;
        });
    }

    _handleOutsideClick(e) {
        if (!this.panel.contains(e.target) && !this.openButton.contains(e.target)) {
            this.close();
        }
    }

    _apply() {
        const params = new URLSearchParams();
        const searchInput = document.getElementById('search-input');
        if (searchInput?.value) {
            params.set('term', searchInput.value);
        }
        this.panel.querySelectorAll('input[type="checkbox"]:checked').forEach(cb => {
            params.append('types', cb.value);
        });
        window.location.href = window.location.pathname + '?' + params.toString();
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const ctrl = new FilterController({
        openButton: document.getElementById('filter-open'),
        closeButton: document.getElementById('filter-close'),
        panel: document.getElementById('filter-panel'),
    });
    ctrl.init();
});
