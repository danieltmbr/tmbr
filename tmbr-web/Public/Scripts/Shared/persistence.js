class PersistenceController {
    constructor({ pendingKeyName = 'editor:pendingClear' } = {}) {
        this.pendingKeyName = pendingKeyName;
    }

    load(key) {
        try {
            const raw = localStorage.getItem(key);
            return raw ? JSON.parse(raw) : null;
        } catch (_) {
            return null;
        }
    }

    save(key, state) {
        try {
            localStorage.setItem(key, JSON.stringify(state));
        } catch (err) {
            console.error(`Couldn't save draft. ${err?.message || err}`);
        }
    }

    clear(key) {
        try {
            localStorage.removeItem(key);
        } catch (_) {
            // ignore
        }
    }

    clearIfPending(key) {
        try {
            const raw = localStorage.getItem(this.pendingKeyName);
            const pending = raw ? JSON.parse(raw) : [];
            if (!Array.isArray(pending) || !pending.includes(key)) return false;
            localStorage.removeItem(key);
            const updated = pending.filter(k => k !== key);
            if (updated.length === 0) {
                localStorage.removeItem(this.pendingKeyName);
            } else {
                localStorage.setItem(this.pendingKeyName, JSON.stringify(updated));
            }
            return true;
        } catch (_) {
            return false;
        }
    }

    markPendingClear(key) {
        try {
            const raw = localStorage.getItem(this.pendingKeyName);
            const pending = raw ? JSON.parse(raw) : [];
            const list = Array.isArray(pending) ? pending : [];
            if (!list.includes(key)) list.push(key);
            localStorage.setItem(this.pendingKeyName, JSON.stringify(list));
        } catch (_) {
            // ignore
        }
    }
}
