self.addEventListener('push', event => {
    const data = event.data?.json() ?? {};
    console.log(event.data)
    console.log(data)
    const title = data.title || 'New Post';
    const options = {
        body: data.body || 'Revealed another layer to my soul.',
        data: { url: data.url || 'https://tmbr.me/' }
    };
    event.waitUntil(
        self.registration.showNotification(title, options)
    );
});

self.addEventListener('notificationclick', event => {
    event.notification.close();
    clients.openWindow(event.notification.data.url);
});
