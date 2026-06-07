const bell = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 13.7608 14.8321"><g><rect height="14.8321" opacity="0" width="13.7608" x="0" y="0"/><path d="M1.26404 11.8851L12.1277 11.8851C12.9143 11.8851 13.3917 11.4613 13.3917 10.8323C13.3917 10.1072 12.709 9.47127 12.0835 8.88223C11.6469 8.47723 11.5045 7.61713 11.4442 6.85003C11.3753 4.16215 10.6311 2.2943 8.80874 1.60365C8.5013 0.712091 7.74421 0.00158197 6.69585 0.00158197C5.64749 0.00158197 4.89041 0.712091 4.58297 1.60365C2.76064 2.2943 2.01638 4.16215 1.94027 6.85003C1.88719 7.61713 1.7376 8.47723 1.30816 8.88223C0.675529 9.47127 0 10.1072 0 10.8323C0 11.4613 0.47742 11.8851 1.26404 11.8851ZM6.69585 14.8321C7.94425 14.8321 8.85638 13.9389 8.93548 12.911L4.45623 12.911C4.52812 13.9389 5.44746 14.8321 6.69585 14.8321Z" fill="currentColor"/></g></svg>'

const bellCrossed = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 15.4472 15.4716"><g><rect height="15.4716" opacity="0" width="15.4472" x="0" y="0"/><path d="M7.53903 15.1518C6.29064 15.1518 5.37851 14.2587 5.29941 13.2307L9.77866 13.2307C9.70676 14.2587 8.78743 15.1518 7.53903 15.1518ZM10.0869 12.2048L2.10722 12.2048C1.3206 12.2048 0.843179 11.781 0.843179 11.1521C0.843179 10.427 1.52591 9.79102 2.15134 9.20197C2.58798 8.79697 2.73037 7.93688 2.78345 7.16978C2.80449 6.42665 2.87661 5.74621 3.01069 5.13863ZM9.65192 1.9234C11.4742 2.61404 12.2185 4.4819 12.2946 7.16978C12.3477 7.93688 12.4973 8.79697 12.9267 9.20197C13.5594 9.79102 14.2349 10.427 14.2349 11.1521C14.2349 11.4243 14.1455 11.6581 13.9799 11.8355L4.54699 2.4092C4.80594 2.20967 5.09863 2.04752 5.42614 1.9234C5.73358 1.03184 6.49067 0.321328 7.53903 0.321328C8.58739 0.321328 9.34448 1.03184 9.65192 1.9234Z" fill="currentColor"/><path d="M1.07732 1.93816L13.5145 14.3578C13.7534 14.5967 14.1433 14.5967 14.3734 14.3578C14.6035 14.1189 14.6123 13.7378 14.3734 13.4989L1.94497 1.0793C1.70609 0.840409 1.3162 0.840409 1.07732 1.0793C0.847219 1.30939 0.847219 1.70806 1.07732 1.93816Z" fill="currentColor"/></g></svg>'

const chevronDown = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 6"><path d="M1 1l4 4 4-4" stroke="currentColor" stroke-width="1.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>'
const chevronRight = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 6 10"><path d="M1 1l4 4-4 4" stroke="currentColor" stroke-width="1.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>'

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
    constructor(bellWrapper, bellToggle) {
        this.bellWrapper = bellWrapper;
        this.bellToggle = bellToggle;
        this.panel = null;
        this._push = null;
        this._contentOptions = null;
        this._snapshot = null;
        this._onBellClick = this._handleBellClick.bind(this);
        this._onOutsideClick = this._handleOutsideClick.bind(this);
    }

    init() {
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
        if (this.panel?.classList.contains('open')) {
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
        if (!this._contentOptions) {
            const res = await fetch('/api/notifications/web-push/content-options');
            const data = await res.json();
            this._contentOptions = data.options ?? [];
        }
        this._renderPanel();
        this._snapshot = this._currentTypes();
        setTimeout(() => {
            document.addEventListener('click', this._onOutsideClick);
        }, 0);
    }

    _close() {
        if (!this.panel) return;
        this.panel.classList.remove('open');
        document.removeEventListener('click', this._onOutsideClick);
        this._applyIfChanged();
    }

    _handleOutsideClick(e) {
        if (this.panel && !this.panel.contains(e.target) && !this.bellWrapper.contains(e.target)) {
            this._close();
        }
    }

    _renderPanel() {
        if (!this.panel) {
            this.panel = document.createElement('aside');
            this.panel.id = 'notification-panel';
            this.panel.className = 'panel popup';
            this.bellWrapper.appendChild(this.panel);
        }

        const isSubscribed = !!this._push.subscription;
        const storedTypes = (localStorage.getItem('notifContentTypes') ?? 'post').split('|').filter(Boolean);

        let html = `<ul class="system-info">`;

        html += `<li class="filter-item">
            <label for="notif-subscribed">Enable notifications</label>
            <input type="checkbox" id="notif-subscribed"${isSubscribed ? ' checked' : ''}>
        </li>`;

        if (isSubscribed && this._contentOptions?.length) {
            html += `<hr>`;
            for (const option of this._contentOptions) {
                if (option.children?.length) {
                    const anyChildChecked = option.children.some(c => storedTypes.includes(c.value));
                    const topChecked = storedTypes.includes(option.value) && !anyChildChecked;
                    html += `<li class="filter-item notif-group">
                        <label for="notif-${option.value}">
                            <input type="checkbox" id="notif-${option.value}" class="notif-top" value="${option.value}"${topChecked ? ' checked' : ''}>
                            ${option.label}
                        </label>
                        <button type="button" class="icon notif-chevron" aria-label="Expand ${option.label}" aria-expanded="${anyChildChecked}">${anyChildChecked ? chevronDown : chevronRight}</button>
                    </li>
                    <ul class="notif-children${anyChildChecked ? ' open' : ''}">`;
                    for (const child of option.children) {
                        const childChecked = storedTypes.includes(child.value);
                        html += `<li class="filter-item">
                            <label for="notif-${child.value}">
                                <input type="checkbox" id="notif-${child.value}" class="notif-child" value="${child.value}"${childChecked ? ' checked' : ''}>
                                ${child.label}
                            </label>
                        </li>`;
                    }
                    html += `</ul>`;
                } else {
                    const checked = storedTypes.includes(option.value);
                    html += `<li class="filter-item">
                        <label for="notif-${option.value}">
                            <input type="checkbox" id="notif-${option.value}" class="notif-top" value="${option.value}"${checked ? ' checked' : ''}>
                            ${option.label}
                        </label>
                    </li>`;
                }
            }
        }

        html += `</ul>`;
        this.panel.innerHTML = html;
        this.panel.classList.add('open');
        this._bindPanelEvents();
    }

    _bindPanelEvents() {
        // Subscribe toggle
        const subscribedCb = this.panel.querySelector('#notif-subscribed');
        subscribedCb?.addEventListener('change', async () => {
            if (subscribedCb.checked) {
                const newSub = await subscribeUser(this._push.service);
                if (newSub) {
                    this._push.subscription = newSub;
                    this._updateBellIcon(true);
                    this._renderPanel();
                } else {
                    subscribedCb.checked = false;
                }
            } else {
                if (this._push.subscription) {
                    await unsubscribeUser(this._push.service, this._push.subscription);
                }
                this._push.subscription = null;
                this._snapshot = null;
                this._updateBellIcon(false);
                this._renderPanel();
            }
        });

        // Chevron disclosure
        this.panel.querySelectorAll('.notif-chevron').forEach(btn => {
            btn.addEventListener('click', e => {
                e.stopPropagation();
                const group = btn.closest('li.notif-group');
                const children = group?.nextElementSibling;
                if (!children?.classList.contains('notif-children')) return;
                const expanded = children.classList.toggle('open');
                btn.setAttribute('aria-expanded', String(expanded));
                btn.innerHTML = expanded ? chevronDown : chevronRight;
            });
        });

        // Top-level checkbox: uncheck children when top is checked
        this.panel.querySelectorAll('.notif-top').forEach(topCb => {
            const group = topCb.closest('li.notif-group');
            if (!group) return;
            const childList = group.nextElementSibling;
            topCb.addEventListener('change', () => {
                if (topCb.checked) {
                    childList?.querySelectorAll('.notif-child').forEach(cb => { cb.checked = false; });
                }
            });
        });

        // Child checkbox: uncheck parent top-level when any child is checked
        this.panel.querySelectorAll('.notif-child').forEach(childCb => {
            childCb.addEventListener('change', () => {
                if (!childCb.checked) return;
                const childList = childCb.closest('.notif-children');
                const group = childList?.previousElementSibling;
                const topCb = group?.querySelector('.notif-top');
                if (topCb) topCb.checked = false;
            });
        });
    }

    _currentTypes() {
        const types = [];
        this.panel?.querySelectorAll('.notif-top:checked, .notif-child:checked').forEach(cb => {
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

    _updateBellIcon(isSubscribed) {
        this.bellToggle.title = isSubscribed ? 'Notification preferences' : 'Enable notifications';
        this.bellToggle.innerHTML = isSubscribed ? bellCrossed : bell;
    }
}

// ---------------------------------------------------------------------------
// Boot
// ---------------------------------------------------------------------------

async function initialiseNotificationToggle() {
    const bellWrapper = document.getElementById('notification-bell-wrapper');
    const bellToggle = document.getElementById('notification-toggle');
    if (!bellWrapper || !bellToggle) return;

    const push = await checkPushSubscription();

    if (!push.service) {
        bellToggle.role = '';
        bellToggle.href = '/notifications';
        return;
    }

    if (push.subscription) {
        localStorage.setItem('pushEndpoint', push.subscription.endpoint);
        bellToggle.title = 'Notification preferences';
        bellToggle.innerHTML = bellCrossed;
    } else {
        localStorage.removeItem('pushEndpoint');
        bellToggle.title = 'Enable notifications';
        bellToggle.innerHTML = bell;
    }

    const ctrl = new NotificationPreferencesController(bellWrapper, bellToggle);
    ctrl.init();
}

document.addEventListener('DOMContentLoaded', async () => {
    await initialiseNotificationToggle();
    await new Promise(requestAnimationFrame);
    const footer = document.getElementById('footer');
    footer.classList.remove('invisible');
});
