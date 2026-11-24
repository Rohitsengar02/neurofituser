// Firebase Cloud Messaging Web Push Client Initializer for NeuroFit App
// Credentials dynamically loaded from backend environment variables (No hardcoded keys)
(function () {
  async function fetchConfig() {
    const endpoints = [
      '/api/notifications/firebase-config',
      'http://localhost:5000/api/notifications/firebase-config'
    ];
    for (const url of endpoints) {
      try {
        const res = await fetch(url);
        if (res.ok) {
          const data = await res.json();
          if (data && data.success && data.config) {
            return data;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  async function initPushNotifications() {
    if (!('Notification' in window) || !('serviceWorker' in navigator)) {
      return;
    }

    try {
      const serverConfig = await fetchConfig();
      if (!serverConfig || !serverConfig.config || !serverConfig.config.apiKey) {
        return;
      }

      const { config, vapidKey } = serverConfig;

      if (!window.firebase.apps.length) {
        window.firebase.initializeApp(config);
      }

      const registration = await navigator.serviceWorker.register('/firebase-messaging-sw.js');

      let permission = Notification.permission;
      if (permission === 'default') {
        permission = await Notification.requestPermission();
      }

      if (permission !== 'granted') return;

      const messaging = window.firebase.messaging();
      const tokenOptions = { serviceWorkerRegistration: registration };
      if (vapidKey) {
        tokenOptions.vapidKey = vapidKey;
      }

      const currentToken = await messaging.getToken(tokenOptions);

      if (currentToken) {
        const registerEndpoints = [
          '/api/notifications/register-token',
          'http://localhost:5000/api/notifications/register-token'
        ];

        for (const regUrl of registerEndpoints) {
          try {
            const res = await fetch(regUrl, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                token: currentToken,
                role: 'user',
                platform: 'web'
              })
            });
            if (res.ok) break;
          } catch (_) {}
        }
      }

      messaging.onMessage((payload) => {
        const title = payload.notification?.title || payload.data?.title || 'NeuroFit Notification';
        const body = payload.notification?.body || payload.data?.body || '';

        if (Notification.permission === 'granted') {
          new Notification(title, {
            body: body,
            icon: '/favicon.png',
            badge: '/favicon.png',
            data: payload.data
          });
        }
      });
    } catch (err) {
      console.warn('FCM App Init notice:', err.message);
    }
  }

  window.addEventListener('load', () => {
    setTimeout(initPushNotifications, 2500);
  });
})();
