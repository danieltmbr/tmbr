class FilterController {
    constructor({ openButton, panel }) {
        this.openButton = openButton;
        this.panel = panel;
        this.param = panel.dataset.param;
        this._snapshot = new Set();
        this._onOpenClick = this.open.bind(this);
        this._onOutsideClick = this._handleOutsideClick.bind(this);
    }

    init() {
        if (this.param === 'languages') {
            this._initFromCookie();
        }
        this.openButton.addEventListener('click', this._onOpenClick);
        this.panel.querySelector('[data-select-all]')
            ?.addEventListener('click', () => this._setAll(true));
        this.panel.querySelector('[data-deselect-all]')
            ?.addEventListener('click', () => this._setAll(false));
    }

    _initFromCookie() {
        const raw = document.cookie.split(';').find(c => c.trim().startsWith('lang_pref='))?.split('=')[1] ?? '';
        const prefs = raw ? raw.split('|') : [];
        this.panel.querySelectorAll('input[type="checkbox"]').forEach(cb => {
            cb.checked = prefs.length === 0 || prefs.includes(cb.value);
        });
    }

    destroy() {
        this.openButton.removeEventListener('click', this._onOpenClick);
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

    _setAll(checked) {
        this.panel.querySelectorAll('input[type="checkbox"]').forEach(cb => {
            cb.checked = checked;
        });
    }

    _handleOutsideClick(e) {
        if (!this.panel.contains(e.target) && !this.openButton.contains(e.target)) {
            this.close();
        }
    }

    _apply() {
        const checked = [];
        this.panel.querySelectorAll('input[type="checkbox"]:checked').forEach(cb => {
            checked.push(cb.value);
        });
        if ('globalPanel' in this.panel.dataset) {
            document.cookie = `lang_pref=${checked.join('|')}; max-age=${365 * 24 * 60 * 60}; path=/; SameSite=Lax`;
            const endpoint = localStorage.getItem('pushEndpoint');
            if (endpoint) {
                fetch('/api/notifications/web-push/subscription', {
                    method: 'PATCH',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ endpoint, languages: checked }),
                    keepalive: true
                });
            }
            window.location.reload();
            return;
        }
        const params = new URLSearchParams(window.location.search);
        params.delete(this.param);
        const searchInput = document.getElementById('search-input');
        if (searchInput?.value) {
            params.set('term', searchInput.value);
        }
        checked.forEach(v => params.append(this.param, v));
        window.location.href = window.location.pathname + '?' + params.toString();
    }
}

document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('[data-filter-panel]').forEach(panel => {
        const ctrl = new FilterController({
            openButton: document.getElementById(panel.dataset.openButtonId),
            panel,
        });
        ctrl.init();
    });
});
