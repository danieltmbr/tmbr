self.addEventListener('push', event => {
    const data = event.data?.json() ?? {};
    const title = data.title || 'New Post';
    const options = {
        body: data.body || 'Revealed another layer to my soul.',
//        icon: data.icon || '/images/bell.png',
        data: { url: data.url || 'https://tmbr.me/' }
    };
    event.waitUntil(
        self.registration.showNotification(title, options)
    );
});

self.addEventListener('notificationclick', event => {
    event.notification.close();
    event.waitUntil(
        clients.openWindow(event.notification.data.url)
    );
});
