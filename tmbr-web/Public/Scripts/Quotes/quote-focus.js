class QuoteFocusController {

    constructor({ section, toggle }, { immersion = null } = {}) {
        this.section = section;
        this.toggle = toggle;
        this.immersion = immersion;
        this.items = Array.from(section.querySelectorAll(':scope > ul > li'));
        this.index = 0;

        this._onToggle = this.onToggle.bind(this);
        this._onWheel = this.onWheel.bind(this);
        this._onKeyDown = this.onKeyDown.bind(this);
        this._onTouchStart = this.onTouchStart.bind(this);
        this._onTouchEnd = this.onTouchEnd.bind(this);

        this._touchStartY = 0;
        this._wheelAccum = 0;
        this._wheelTimer = null;
        this._wheelCooldown = false;
        this._wheelCooldownTimer = null;
        this._isAnimating = false;
        this._animationTimer = null;
    }

    init() {
        if (this.items.length === 0) return;

        this.toggle.removeAttribute('hidden');
        this.toggle.addEventListener('click', this._onToggle);

        const hasSearch = new URLSearchParams(window.location.search).has('term');
        const saved = localStorage.getItem('quotes-layout');
        if (hasSearch || saved === 'list') {
            this.enterList({ save: !hasSearch });
        } else {
            this.enterFocused();
        }
    }

    destroy() {
        this.toggle.removeEventListener('click', this._onToggle);
        this.removeGestureListeners();
        this.immersion?.destroy();
        clearTimeout(this._wheelTimer);
        clearTimeout(this._wheelCooldownTimer);
        clearTimeout(this._animationTimer);
    }

    // ---- Mode switching ----

    _currentListIndex() {
        const mid = window.scrollY + window.innerHeight / 2;
        let best = 0, bestDist = Infinity;
        this.items.forEach((item, i) => {
            const rect = item.getBoundingClientRect();
            const itemMid = window.scrollY + rect.top + rect.height / 2;
            const dist = Math.abs(itemMid - mid);
            if (dist < bestDist) { bestDist = dist; best = i; }
        });
        return best;
    }

    enterFocused() {
        this.index = this._currentListIndex();
        this.section.classList.add('focused');
        document.body.classList.add('quotes-focused');
        this.items.forEach((item, i) => {
            item.classList.toggle('is-active', i === this.index);
        });
        window.scrollTo({ top: 0, behavior: 'instant' });
        this.addGestureListeners();
        this.immersion?.init();
        localStorage.setItem('quotes-layout', 'focused');
    }

    enterList({ save = true } = {}) {
        this.section.classList.remove('focused');
        document.body.classList.remove('quotes-focused');
        this.items.forEach(item => item.classList.remove('is-active'));
        this.items[this.index]?.scrollIntoView({ block: 'center', behavior: 'instant' });
        this.removeGestureListeners();
        this.immersion?.destroy();
        if (save) localStorage.setItem('quotes-layout', 'list');
    }

    onToggle() {
        if (this.section.classList.contains('focused')) {
            this.enterList();
        } else {
            this.enterFocused();
        }
    }

    // ---- Navigation ----

    // Returns true when the active li's relevant edge has reached (or passed)
    // the viewport boundary in the given direction.
    // Absolutely-positioned li would have zero layout height; now that li items
    // are in normal flow, getBoundingClientRect() reflects real on-screen geometry.
    _atBoundary(dir) {
        const el = this.items[this.index];
        const EPS = 2;
        if (dir > 0) {
            return el.getBoundingClientRect().bottom <= window.innerHeight + EPS;
        } else {
            return el.getBoundingClientRect().top >= -EPS;
        }
    }

    advance(dir) {
        if (this._isAnimating) return;
        const next = Math.max(0, Math.min(this.items.length - 1, this.index + dir));
        if (next === this.index) return;

        this._isAnimating = true;
        window.scrollTo({ top: 0, behavior: 'instant' });

        const outgoing = this.items[this.index];
        const incoming = this.items[next];
        this.index = next;

        const direction = dir > 0 ? 'forward' : 'backward';
        outgoing.classList.remove('is-active');
        outgoing.classList.add(`is-leaving-${direction}`);
        incoming.classList.add(`is-entering-${direction}`, 'is-active');

        const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        clearTimeout(this._animationTimer);
        this._animationTimer = setTimeout(() => {
            outgoing.classList.remove(`is-leaving-${direction}`);
            incoming.classList.remove(`is-entering-${direction}`);
            this._isAnimating = false;
        }, reduced ? 0 : 300);
    }

    // ---- Gesture listeners ----

    // Wheel listener is non-passive so we can call preventDefault() to stop
    // native page scroll when we're handling quote navigation at a boundary.
    // When the active quote is taller than the viewport and not yet scrolled
    // to its edge, we return without preventing default so the page scrolls
    // naturally to let the user read the rest of the quote.
    addGestureListeners() {
        window.addEventListener('wheel', this._onWheel, { passive: false });
        window.addEventListener('touchstart', this._onTouchStart, { passive: true });
        window.addEventListener('touchend', this._onTouchEnd, { passive: true });
        document.addEventListener('keydown', this._onKeyDown);
    }

    removeGestureListeners() {
        window.removeEventListener('wheel', this._onWheel);
        window.removeEventListener('touchstart', this._onTouchStart);
        window.removeEventListener('touchend', this._onTouchEnd);
        document.removeEventListener('keydown', this._onKeyDown);
    }

    onWheel(event) {
        const dir = event.deltaY > 0 ? 1 : event.deltaY < 0 ? -1 : 0;

        if (dir !== 0 && !this._atBoundary(dir)) {
            // Not at the edge of this quote yet — let the page scroll naturally.
            return;
        }

        // At boundary (or zero delta): prevent native scroll and handle navigation.
        event.preventDefault();

        if (this._wheelCooldown) return;

        this._wheelAccum += event.deltaY;
        clearTimeout(this._wheelTimer);
        this._wheelTimer = setTimeout(() => { this._wheelAccum = 0; }, 80);

        if (Math.abs(this._wheelAccum) >= 50) {
            const advDir = this._wheelAccum > 0 ? 1 : -1;
            this._wheelAccum = 0;
            this._wheelCooldown = true;
            clearTimeout(this._wheelCooldownTimer);
            this._wheelCooldownTimer = setTimeout(() => { this._wheelCooldown = false; }, 700);
            this.advance(advDir);
        }
    }

    onTouchStart(event) {
        this._touchStartY = event.changedTouches[0].clientY;
    }

    onTouchEnd(event) {
        const deltaY = this._touchStartY - event.changedTouches[0].clientY;
        if (Math.abs(deltaY) >= 40) {
            const dir = deltaY > 0 ? 1 : -1;
            if (this._atBoundary(dir)) {
                this.advance(dir);
            }
        }
    }

    onKeyDown(event) {
        switch (event.key) {
            case 'ArrowDown':
            case 'PageDown':
            case ' ':
                event.preventDefault();
                this.advance(1);
                break;
            case 'ArrowUp':
            case 'PageUp':
                event.preventDefault();
                this.advance(-1);
                break;
        }
    }
}
