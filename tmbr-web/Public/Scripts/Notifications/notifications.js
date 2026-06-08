// ---------------------------------------------------------------------------
// Push helpers
// ---------------------------------------------------------------------------

async function loadVAPIDKey() {
    const httpResponse = await fetch(`/api/notifications/web-push/vapid`);
    const webPushOptions = await httpResponse.json();
    if (httpResponse.status != 200) {
        throw new Error(webPushOptions.reason);
    }
    return webPushOptions.vapid;
}

async function registerServiceWorker() {
    if ('serviceWorker' in navigator && 'PushManager' in window) {
        try {
            const registration = await navigator.serviceWorker.register("/service-worker.mjs", { type: "module" });
            return registration;
        } catch (error) {
            console.error('Service Worker registration failed:', error);
        }
    }
    return null;
}

async function checkPushSubscription() {
    const service = await registerServiceWorker();
    const subscription = await service?.pushManager?.getSubscription();
    return { service, subscription };
}

async function subscribeUser(service) {
    const permission = await Notification.requestPermission();
    if (permission !== 'granted') {
        alert('Notifications permission not granted');
        return null;
    }
    try {
        const applicationServerKey = await loadVAPIDKey();
        const subscription = await service.pushManager.subscribe({
            userVisibleOnly: true,
            applicationServerKey: applicationServerKey
        });
        const langCookie = document.cookie.split(';').find(c => c.trim().startsWith('lang_pref='));
        const languages = langCookie ? (langCookie.split('=')[1] || '').split('|').filter(Boolean) : [];
        await fetch('/api/notifications/web-push/subscription', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ ...subscription.toJSON(), languages, contentTypes: ['post'] })
        });
        localStorage.setItem('pushEndpoint', subscription.endpoint);
        localStorage.setItem('notifContentTypes', 'post');
        return subscription;
    } catch (error) {
        console.error('Subscription failed:', error);
        return null;
    }
}

async function unsubscribeUser(service, subscription) {
    await fetch('/api/notifications/web-push/subscription', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(subscription)
    });
    localStorage.removeItem('pushEndpoint');
    localStorage.removeItem('notifContentTypes');
    return subscription.unsubscribe();
}

async function savePreferences(endpoint, languages, contentTypes) {
    await fetch('/api/notifications/web-push/subscription', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ endpoint, languages, contentTypes }),
        keepalive: true
    });
}

// ---------------------------------------------------------------------------
// NotificationPreferencesController
// ---------------------------------------------------------------------------

class NotificationPreferencesController {
    constructor(bellToggle) {
        this.bellToggle = bellToggle;
        this.panel = null;
        this._push = null;
        this._panelLoaded = false;
        this._snapshot = null;
        this._onBellClick = this._handleBellClick.bind(this);
        this._onOutsideClick = this._handleOutsideClick.bind(this);
    }

    init() {
        this.panel = document.createElement('aside');
        this.panel.id = 'notification-panel';
        this.panel.className = 'panel popup';
        this.bellToggle.insertAdjacentElement('afterend', this.panel);
        this.bellToggle.addEventListener('click', this._onBellClick);
        this.bellToggle.addEventListener('touchend', this._onBellClick, { passive: false });
    }

    destroy() {
        this.bellToggle.removeEventListener('click', this._onBellClick);
        this.bellToggle.removeEventListener('touchend', this._onBellClick);
        document.removeEventListener('click', this._onOutsideClick);
        this.panel?.remove();
    }

    async _handleBellClick(e) {
        e.preventDefault();
        e.stopPropagation();
        if (this.panel.classList.contains('open')) {
            this._close();
        } else {
            await this._open();
        }
    }

    async _open() {
        this._push = await checkPushSubscription();
        if (!this._push.service) {
            location.href = '/notifications';
            return;
        }
        if (this._push.subscription) {
            localStorage.setItem('pushEndpoint', this._push.subscription.endpoint);
        }
        if (!this._panelLoaded) {
            const res = await fetch('/notifications/panel');
            this.panel.innerHTML = await res.text();
            this._bindPanelEvents();
            this._panelLoaded = true;
        }
        this._syncState();
        this._snapshot = this._currentTypes();
        this.panel.classList.add('open');
        setTimeout(() => {
            document.addEventListener('click', this._onOutsideClick);
        }, 0);
    }

    _close() {
        this.panel.classList.remove('open');
        document.removeEventListener('click', this._onOutsideClick);
        this._applyIfChanged();
    }

    _handleOutsideClick(e) {
        if (!this.panel.contains(e.target) && !this.bellToggle.contains(e.target)) {
            this._close();
        }
    }

    _syncState() {
        const isSubscribed = !!this._push.subscription;
        const subscribedCb = this.panel.querySelector('#notification-subscribed');
        if (subscribedCb) subscribedCb.checked = isSubscribed;

        if (!isSubscribed) {
            this.panel.querySelectorAll('.notification-top, .notification-child').forEach(cb => { cb.checked = false; });
            return;
        }

        const storedTypes = (localStorage.getItem('notifContentTypes') ?? '').split('|').filter(Boolean);
        this.panel.querySelectorAll('.notification-top, .notification-child').forEach(cb => {
            cb.checked = storedTypes.includes(cb.value);
        });
    }

    _bindPanelEvents() {
        const subscribedCb = this.panel.querySelector('#notification-subscribed');
        subscribedCb?.addEventListener('change', async () => {
            if (subscribedCb.checked) {
                const newSub = await subscribeUser(this._push.service);
                if (newSub) {
                    this._push.subscription = newSub;
                    this._syncState();
                } else {
                    subscribedCb.checked = false;
                }
            } else {
                if (this._push.subscription) {
                    await unsubscribeUser(this._push.service, this._push.subscription);
                }
                this._push.subscription = null;
                this._snapshot = null;
                this._syncState();
            }
        });

        // Top-level: sync all children to match parent check state
        this.panel.querySelectorAll('.notification-top').forEach(topCb => {
            const childList = topCb.closest('li.notification-group')?.nextElementSibling;
            topCb.addEventListener('change', () => {
                childList?.querySelectorAll('.notification-child').forEach(cb => { cb.checked = topCb.checked; });
            });
        });

        this.panel.querySelector('[data-select-all]')
            ?.addEventListener('click', () => {
                this.panel.querySelectorAll('.notification-top').forEach(cb => { cb.checked = true; });
                this.panel.querySelectorAll('.notification-child').forEach(cb => { cb.checked = false; });
            });

        this.panel.querySelector('[data-deselect-all]')
            ?.addEventListener('click', () => {
                this.panel.querySelectorAll('.notification-top, .notification-child').forEach(cb => { cb.checked = false; });
            });
    }

    _currentTypes() {
        const types = [];
        this.panel.querySelectorAll('.notification-top:checked, .notification-child:checked').forEach(cb => {
            types.push(cb.value);
        });
        return types.sort().join('|');
    }

    _applyIfChanged() {
        if (!this._push?.subscription) return;
        const current = this._currentTypes();
        if (current === this._snapshot) return;

        const endpoint = this._push.subscription.endpoint;
        const contentTypes = current.split('|').filter(Boolean);
        const langCookie = document.cookie.split(';').find(c => c.trim().startsWith('lang_pref='));
        const languages = langCookie ? (langCookie.split('=')[1] || '').split('|').filter(Boolean) : [];

        localStorage.setItem('notifContentTypes', current);
        savePreferences(endpoint, languages, contentTypes);
    }

}

// ---------------------------------------------------------------------------
// Boot
// ---------------------------------------------------------------------------

async function initialiseNotificationToggle() {
    const bellToggle = document.getElementById('notification-toggle');
    if (!bellToggle) return;

    const push = await checkPushSubscription();

    if (!push.service) {
        bellToggle.role = '';
        bellToggle.href = '/notifications';
        return;
    }

    if (push.subscription) {
        localStorage.setItem('pushEndpoint', push.subscription.endpoint);
    } else {
        localStorage.removeItem('pushEndpoint');
    }

    const ctrl = new NotificationPreferencesController(bellToggle);
    ctrl.init();
}

document.addEventListener('DOMContentLoaded', async () => {
    await initialiseNotificationToggle();
    await new Promise(requestAnimationFrame);
    const footer = document.getElementById('footer');
    footer.classList.remove('invisible');
});
