/**
 * Firebase Cloud Messaging Service Worker
 * Pizza One - Order Notifications
 *
 * This service worker runs in the browser background and handles:
 *   1. Background push notifications (when PWA is closed or phone is locked)
 *   2. Notification click events → opens the app to the correct order
 *   3. Cache-first strategy for offline loading
 *
 * IMPORTANT for iOS:
 *   - This ONLY works when the app has been added to the Home Screen
 *   - iOS 16.4+ is required for Web Push
 *   - The service worker scope MUST match: /apporders/
 */

// ================================================================
//  Firebase SDK Imports (use compat version in service workers)
// ================================================================
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

// ================================================================
//  Firebase Configuration
//  NOTE: Replace these values with your Firebase Web App credentials
//  from Firebase Console > Project Settings > Your apps > Web app
// ================================================================
const FIREBASE_CONFIG = {
  apiKey: "AIzaSyDYZnpN0yNJbLDWSsgtlBsaMNvrvxl8eFw",
  authDomain: "pizzaone-25548.firebaseapp.com",
  projectId: "pizzaone-25548",
  storageBucket: "pizzaone-25548.firebasestorage.app",
  messagingSenderId: "2627187244",
  appId: "1:2627187244:web:78c7f45b4d3651302dd789",
  measurementId: "G-XCJMB7GCMF",
};

// ================================================================
//  App Constants
// ================================================================
const APP_NAME = 'Pizza One';
const APP_URL = 'https://pizzaonerestaurant.com/apporders/';
const CACHE_NAME = 'pizzaone-pwa-v9';
const NOTIFICATION_ICON = '/apporders/icons/Icon-192.png';
const NOTIFICATION_BADGE = '/apporders/icons/Icon-192.png';

// ================================================================
//  Initialize Firebase
// ================================================================
let messaging = null;
try {
  firebase.initializeApp(FIREBASE_CONFIG);
  messaging = firebase.messaging();
  console.log('[Pizza SW] Firebase initialized successfully');
} catch (e) {
  console.error('[Pizza SW] Firebase initialization failed:', e);
}

// ================================================================
//  Background Message Handler
//  Called when app is closed/in background and a push arrives
// ================================================================
if (messaging) {
  messaging.onBackgroundMessage(function(payload) {
    console.log('[Pizza SW] Background message received:', payload);

    const notificationTitle = payload.notification?.title
      || payload.data?.title
      || '🍕 Nouvelle Commande !';

    const notificationBody = payload.notification?.body
      || payload.data?.body
      || 'Une nouvelle commande est en attente de confirmation.';

    const orderId = payload.data?.order_id || '';

    const notificationOptions = {
      body: notificationBody,
      icon: NOTIFICATION_ICON,
      badge: NOTIFICATION_BADGE,
      tag: `order-${orderId || Date.now()}`,       // Collapse duplicate notifications for same order
      renotify: true,                               // Re-ring even if same tag
      requireInteraction: true,                     // Keeps notification visible until user taps (iOS honor)
      vibrate: [200, 100, 200, 100, 200],           // Vibration pattern
      data: {
        order_id: orderId,
        url: APP_URL,
        timestamp: Date.now(),
      },
      actions: [
        {
          action: 'view_order',
          title: '👁 Voir la commande',
        },
        {
          action: 'dismiss',
          title: '✕ Ignorer',
        },
      ],
    };

    // Show the notification to the user
    return self.registration.showNotification(notificationTitle, notificationOptions);
  });
}

// ================================================================
//  Notification Click Handler
//  When user taps the notification, open the app
// ================================================================
self.addEventListener('notificationclick', function(event) {
  console.log('[Pizza SW] Notification clicked:', event.action, event.notification.data);

  event.notification.close();

  if (event.action === 'dismiss') {
    return; // User dismissed
  }

  // Build target URL (always open the PWA)
  const orderId = event.notification.data?.order_id;
  const targetUrl = APP_URL; // The Flutter app handles routing internally

  event.waitUntil(
    // Try to focus existing open window first
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      // Look for an existing open window for this app
      for (let i = 0; i < clientList.length; i++) {
        const client = clientList[i];
        if (client.url.startsWith(APP_URL) && 'focus' in client) {
          // Post a message to the existing window to navigate to the order
          if (orderId) {
            client.postMessage({ type: 'OPEN_ORDER', order_id: orderId });
          }
          return client.focus();
        }
      }
      // No existing window found → open a new one
      if (clients.openWindow) {
        return clients.openWindow(targetUrl).then(function(newClient) {
          // Give Flutter time to initialize, then send the navigation message
          if (newClient && orderId) {
            setTimeout(function() {
              newClient.postMessage({ type: 'OPEN_ORDER', order_id: orderId });
            }, 2000);
          }
        });
      }
    })
  );
});

// ================================================================
//  Push Event Handler (raw Web Push, for browsers without FCM SDK)
//  This is a fallback in case FCM messaging.onBackgroundMessage fails
// ================================================================
self.addEventListener('push', function(event) {
  if (!event.data) {
    console.log('[Pizza SW] Push received but no data');
    return;
  }

  let payload = {};
  try {
    payload = event.data.json();
  } catch (e) {
    payload = { notification: { title: '🍕 Pizza One', body: event.data.text() } };
  }

  // If Firebase already handled this, avoid showing duplicate
  if (payload.from && messaging) {
    return; // Firebase SDK handles this
  }

  const title = payload.notification?.title || payload.data?.title || '🍕 Nouvelle Commande !';
  const options = {
    body: payload.notification?.body || payload.data?.body || 'Nouvelle commande reçue',
    icon: NOTIFICATION_ICON,
    badge: NOTIFICATION_BADGE,
    requireInteraction: true,
    data: payload.data || {},
  };

  event.waitUntil(self.registration.showNotification(title, options));
});

// ================================================================
//  Service Worker Lifecycle
// ================================================================
self.addEventListener('install', function(event) {
  console.log('[Pizza SW] Service Worker installing...');
  // Take control immediately without waiting
  self.skipWaiting();
});

self.addEventListener('activate', function(event) {
  console.log('[Pizza SW] Service Worker activating...');
  event.waitUntil(
    Promise.all([
      // Take control of all open clients immediately
      clients.claim(),
      // Clean up old caches
      caches.keys().then(function(cacheNames) {
        return Promise.all(
          cacheNames
            .filter(name => name !== CACHE_NAME)
            .map(name => {
              console.log('[Pizza SW] Deleting old cache:', name);
              return caches.delete(name);
            })
        );
      }),
    ])
  );
});

// ================================================================
//  Fetch Handler – Network-First for app updates, cache fallback
// ================================================================
self.addEventListener('fetch', function(event) {
  const url = new URL(event.request.url);

  // Never intercept API requests
  if (url.pathname.startsWith('/api/')) {
    return;
  }

  // Network-First strategy: always fetch latest code from server, fallback to cache if offline
  event.respondWith(
    fetch(event.request)
      .then(function(networkResponse) {
        if (networkResponse && networkResponse.status === 200 && networkResponse.type === 'basic') {
          const responseToCache = networkResponse.clone();
          caches.open(CACHE_NAME).then(function(cache) {
            cache.put(event.request, responseToCache);
          });
        }
        return networkResponse;
      })
      .catch(function() {
        return caches.match(event.request).then(function(cachedResponse) {
          if (cachedResponse) return cachedResponse;
          if (event.request.mode === 'navigate') {
            return caches.match('/apporders/index.html');
          }
        });
      })
  );
});

// ================================================================
//  Message Handler – receive messages from Flutter app
// ================================================================
self.addEventListener('message', function(event) {
  console.log('[Pizza SW] Message from Flutter:', event.data);

  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});
