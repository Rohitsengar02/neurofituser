// Firebase Cloud Messaging Service Worker for NeuroFit App Web Push
// Dynamically reads config from server environment variables - No hardcoded API keys
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

async function initServiceWorker() {
  const endpoints = [
    '/api/notifications/firebase-config',
    'http://localhost:5000/api/notifications/firebase-config'
  ];

  for (const url of endpoints) {
    try {
      const res = await fetch(url);
      if (res.ok) {
        const data = await res.json();
        if (data && data.success && data.config && data.config.apiKey) {
          if (!firebase.apps.length) {
            firebase.initializeApp(data.config);
          }
          const messaging = firebase.messaging();
          messaging.onBackgroundMessage((payload) => {
            const title = payload.notification?.title || payload.data?.title || 'NeuroFit Notification';
            const options = {
              body: payload.notification?.body || payload.data?.body || 'You have a new update in NeuroFit',
              icon: '/favicon.png',
              badge: '/favicon.png',
              data: payload.data || {},
              vibrate: [200, 100, 200],
            };
            self.registration.showNotification(title, options);
          });
          break;
        }
      }
    } catch (_) {}
  }
}

initServiceWorker();

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((windowClients) => {
      for (let client of windowClients) {
        if (client.url.includes(self.registration.scope) && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
