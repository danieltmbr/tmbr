const bell = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 13.7608 14.8321"><g><rect height="14.8321" opacity="0" width="13.7608" x="0" y="0"/><path d="M1.26404 11.8851L12.1277 11.8851C12.9143 11.8851 13.3917 11.4613 13.3917 10.8323C13.3917 10.1072 12.709 9.47127 12.0835 8.88223C11.6469 8.47723 11.5045 7.61713 11.4442 6.85003C11.3753 4.16215 10.6311 2.2943 8.80874 1.60365C8.5013 0.712091 7.74421 0.00158197 6.69585 0.00158197C5.64749 0.00158197 4.89041 0.712091 4.58297 1.60365C2.76064 2.2943 2.01638 4.16215 1.94027 6.85003C1.88719 7.61713 1.7376 8.47723 1.30816 8.88223C0.675529 9.47127 0 10.1072 0 10.8323C0 11.4613 0.47742 11.8851 1.26404 11.8851ZM6.69585 14.8321C7.94425 14.8321 8.85638 13.9389 8.93548 12.911L4.45623 12.911C4.52812 13.9389 5.44746 14.8321 6.69585 14.8321Z" fill="currentColor"/></g></svg>'

const bellCrossed = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 15.4472 15.4716"><g><rect height="15.4716" opacity="0" width="15.4472" x="0" y="0"/><path d="M7.53903 15.1518C6.29064 15.1518 5.37851 14.2587 5.29941 13.2307L9.77866 13.2307C9.70676 14.2587 8.78743 15.1518 7.53903 15.1518ZM10.0869 12.2048L2.10722 12.2048C1.3206 12.2048 0.843179 11.781 0.843179 11.1521C0.843179 10.427 1.52591 9.79102 2.15134 9.20197C2.58798 8.79697 2.73037 7.93688 2.78345 7.16978C2.80449 6.42665 2.87661 5.74621 3.01069 5.13863ZM9.65192 1.9234C11.4742 2.61404 12.2185 4.4819 12.2946 7.16978C12.3477 7.93688 12.4973 8.79697 12.9267 9.20197C13.5594 9.79102 14.2349 10.427 14.2349 11.1521C14.2349 11.4243 14.1455 11.6581 13.9799 11.8355L4.54699 2.4092C4.80594 2.20967 5.09863 2.04752 5.42614 1.9234C5.73358 1.03184 6.49067 0.321328 7.53903 0.321328C8.58739 0.321328 9.34448 1.03184 9.65192 1.9234Z" fill="currentColor"/><path d="M1.07732 1.93816L13.5145 14.3578C13.7534 14.5967 14.1433 14.5967 14.3734 14.3578C14.6035 14.1189 14.6123 13.7378 14.3734 13.4989L1.94497 1.0793C1.70609 0.840409 1.3162 0.840409 1.07732 1.0793C0.847219 1.30939 0.847219 1.70806 1.07732 1.93816Z" fill="currentColor"/></g></svg>'

// Load VAPID config from backend
async function loadVAPIDKey() {
    const httpResponse = await fetch(`/api/notifications/web-push/vapid`);
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
        await fetch('/api/notifications/web-push/subscription', {
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
    await fetch('/api/notifications/web-push/subscription', {
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
        location.href = 'https://tmbr.me/notifications';
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
    const notificationToggle = document.getElementById('notification-toggle');
    if (!notificationToggle) return;
    
    if (isSubscribed) {
        notificationToggle.title = 'Disable notifications';
        notificationToggle.innerHTML = bellCrossed;
    } else {
        notificationToggle.title = 'Enable notifications';
        notificationToggle.innerHTML = bell;
    }
}

async function initialiseNotificationToggle() {
    const notificationToggle = document.getElementById('notification-toggle');
    const push = await checkPushSubscription();
    
    if (!push.service) {
        notificationToggle.role = '';
        notificationToggle.href = '/notifications';
    } else {
        const handler = async event => {
          event.preventDefault();
          event.stopPropagation();
          await togglePushSubscription();
        };
        notificationToggle?.addEventListener('click', handler);
        notificationToggle?.addEventListener('touchend', handler, { passive: false });
        updateNotificationToggle(!!push.subscription);
    }
}

document.addEventListener('DOMContentLoaded', async () => {
    await initialiseNotificationToggle();
    await new Promise(requestAnimationFrame);
    const footer = document.getElementById('footer')
    footer.classList.remove('invisible')
});
