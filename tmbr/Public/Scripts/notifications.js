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

    const service = await registerServiceWorker();
    if (!service) return;
    
    const subscription = await service.pushManager.getSubscription();
    if (subscription) {
        const result = await unsubscribeUser(service, subscription);
        if (result) {
            console.log('Unsubscribed from push notifications.');
            // Update the bell icon (e.g., change color or state) if desired.
        }
    } else {
        const newSub = await subscribeUser(service);
        if (newSub) {
            console.log('Subscribed to push notifications.');
            // Update the bell icon (e.g., change color or state) if desired.
        }
    }
}

// Attach click listener to the bell icon.
document.addEventListener('DOMContentLoaded', () => {
    const notificationToggle = document.getElementById('toggle-notifications');
    if (!notificationToggle) return;
    
    const handler = async event => {
      event.preventDefault();
      event.stopPropagation();
      await togglePushSubscription();
    };

    notificationToggle.addEventListener('click', handler);
    notificationToggle.addEventListener('touchend', handler, { passive: false });
});
