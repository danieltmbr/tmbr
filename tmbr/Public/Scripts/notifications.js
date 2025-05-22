// Load VAPID config from backend
async function loadVAPIDKey() {
    const httpResponse = await fetch(`/api/notifications/vapid`);
    const webPushOptions = await httpResponse.json();
    if (httpResponse.status != 200) {
        throw new Error(webPushOptions.reason);
    }
    return webPushOptions.vapid;
}

// Register the service worker and subscribe the user.
async function registerServiceWorker() {
    if ('serviceWorker' in navigator && 'PushManager' in window) {
        try {
            const registration = await navigator.serviceWorker.register("/service-worker.mjs", { type: "module" });
            console.log('Service Worker registered:', registration);
            return registration;
        } catch (error) {
            console.error('Service Worker registration failed:', error);
        }
    } else {
        console.error('Push messaging is not supported');
    }
    return null;
}

async function checkPushSubscription() {
    const service = await registerServiceWorker();
    const subscription = await service?.pushManager?.getSubscription();
    return { service, subscription };
}

// Subscribe user to push notifications.
async function subscribeUser(service) {
    // Request notification permission from the user.
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
        await fetch('/api/notifications/subscription', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(subscription)
        });
        return subscription;
    } catch (error) {
        console.error('Subscription failed:', error);
        return null;
    }
}

// Unsubscribe user from push notifications.
async function unsubscribeUser(service, subscription) {
    await fetch('/api/notifications/subscription', {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(subscription)
    });
    return subscription.unsubscribe();
}

// Toggle push notification subscription when bell icon is clicked.
async function togglePushSubscription() {
    console.log('Toggle push notifications.');
    const push = await checkPushSubscription();

    if (!push.service) {
        displayModal(true);
    } else if (push.subscription) {
        const result = await unsubscribeUser(push.service, push.subscription);
        if (result) {
            console.log('Unsubscribed from push notifications.');
            updateNotificationToggle(false);
        }
    } else {
        const newSub = await subscribeUser(push.service);
        if (newSub) {
            console.log('Subscribed to push notifications.');
            updateNotificationToggle(true);
        }
    }
}

function updateNotificationToggle(isSubscribed) {
  const btn = document.getElementById('notification-toggle');
  if (!btn) return;

  if (isSubscribed) {
    btn.title = 'Disable notifications';
    btn.innerHTML = `Unsubscribe`;
  } else {
    btn.title = 'Enable notifications';
    btn.innerHTML = `Subscribe`;
  }
}

let scrollLockPositionY = 0;

function lockBodyScroll() {
    scrollLockPositionY = window.scrollY || document.documentElement.scrollTop;
    document.body.style.position = 'fixed';
    document.body.style.top = `-${scrollLockPositionY}px`;
}

function unlockBodyScroll() {
  document.body.style.position = '';
  document.body.style.top = '';
  window.scrollTo(0, scrollLockPositionY);
}

function displayModal(show) {
    show ? lockBodyScroll() : unlockBodyScroll();
    document.getElementById('modal').classList.toggle('open', show);
}

// Attach click listener to the bell icon.
document.addEventListener('DOMContentLoaded', async () => {
    // Setup modal close handler
    const modalClose = document.getElementById('modal-close');
    modalClose?.addEventListener('click', () => displayModal(false));
    
    // Setup notification toggle handler
    const notificationToggle = document.getElementById('notification-toggle');
    const handler = async event => {
      event.preventDefault();
      event.stopPropagation();
      await togglePushSubscription();
    };
    notificationToggle?.addEventListener('click', handler);
    notificationToggle?.addEventListener('touchend', handler, { passive: false });
    
    // Setup initial state for notification toggle
    const push = await checkPushSubscription();
    updateNotificationToggle(!!push.subscription);
});
