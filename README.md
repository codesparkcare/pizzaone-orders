# Pizza One — Flutter Order Management App

## 📱 About

A premium Flutter app for **Pizza One Restaurant** staff and admins to:
- **Receive real-time order notifications** from `https://pizzaonerestaurant.com/`
- **Manage orders** (accept, prepare, deliver, cancel) with full workflow
- **Get instant audio alarms** when new orders arrive
- **View customer info** with 1-tap calling & Google Maps
- **Generate receipt tickets** for printing

---

## 🚀 Setup

### 1. Flutter Project

```bash
flutter pub get
flutter run
```

### 2. Backend API (Already Deployed in XAMPP)

The PHP API has been created at `/Applications/XAMPP/xamppfiles/htdocs/pizzaone/application/controllers/Api.php`

**API Endpoints:**
| Method | URL | Description |
|--------|-----|-------------|
| GET | `/api` | Health check |
| POST | `/api/login` | Staff/Admin authentication |
| GET | `/api/orders` | Order list with filters |
| GET | `/api/orders/{id}` | Single order details |
| POST | `/api/orders/{id}/status` | Update order status |
| GET | `/api/dashboard` | Stats dashboard |
| GET | `/api/shops` | Active shop list |
| POST | `/api/register_token` | Register FCM device token |
| POST | `/api/unregister_token` | Remove device token |
| GET | `/api/test_notification` | Send test push |

### 3. Firebase Setup (Required for Push Notifications)

1. Go to [Firebase Console](https://console.firebase.google.com/project/pizzaone-25548)
2. **Android:** Download `google-services.json` → place in `android/app/`
3. **iOS:** Download `GoogleService-Info.plist` → place in `ios/Runner/`
4. Get the **FCM Server Key** from Firebase Console → Project Settings → Cloud Messaging
5. In the database, run:
   ```sql
   UPDATE fcm_settings SET server_key = 'YOUR_FCM_SERVER_KEY_HERE' WHERE id = 1;
   ```

### 4. Login Credentials

| Username | Password | Role |
|----------|----------|------|
| `superadmin` | `Pizza@123*` | Super Admin (all shops) |
| `admin` | `admin123` | Admin (all shops) |
| `staff` | `Pizza@123*` | Staff (assigned shop) |

---

## 🔧 App Architecture

```
lib/
├── core/
│   ├── api/
│   │   ├── api_client.dart       # HTTP client with timeout/error handling
│   │   └── api_constants.dart    # URLs & endpoints
│   ├── theme/
│   │   └── app_theme.dart        # Dark luxury brand theme
│   └── utils/
│       ├── audio_alert_service.dart     # Order alarm chime
│       ├── notification_service.dart    # FCM + local notifications
│       └── receipt_formatter.dart       # Thermal receipt text
├── models/
│   ├── order_model.dart          # Order data + status helpers
│   ├── order_item_model.dart     # Individual item model
│   ├── shop_model.dart           # Shop branch model
│   └── user_model.dart           # Staff/admin user model
├── providers/
│   ├── auth_provider.dart        # Login, auto-login, logout
│   ├── order_provider.dart       # Real-time polling, alarms
│   └── settings_provider.dart   # URL, sound, refresh config
├── screens/
│   ├── splash_screen.dart        # Animated splash with auto-auth
│   ├── login_screen.dart         # Staff login portal
│   ├── dashboard_screen.dart     # Live order dashboard
│   ├── order_detail_screen.dart  # Full order view + status actions
│   ├── receipt_preview_screen.dart # Receipt ticket preview
│   └── settings_screen.dart     # App configuration
└── widgets/
    ├── audio_alarm_banner.dart   # Pulsing alarm alert banner
    ├── order_card.dart           # Order list card
    ├── order_filter_bar.dart     # Status filter tabs
    ├── server_indicator_chip.dart # Live/Local server toggle
    ├── status_badge.dart         # Order status badge
    └── summary_stat_card.dart   # Dashboard metric card
```

---

## 🎨 Design System

- **Theme:** Dark obsidian luxury (`#0D0E12` background)
- **Brand:** Orange flame primary `#FF5722`, Gold accent `#FFB300`
- **Font:** [Outfit](https://fonts.google.com/specimen/Outfit) via Google Fonts
- **Status Colors:** Amber (pending) → Blue (confirmed) → Purple (preparing) → Cyan (ready) → Green (delivered)

---

## 🔔 Push Notification Flow

```
Customer orders on website
       ↓
PHP Cart.php saves order + calls send_fcm_new_order_notification()
       ↓
Firebase FCM sends push to all registered devices
       ↓
Flutter app receives FCM message in foreground/background
       ↓
🔔 Audio alarm starts ringing + banner shows
       ↓
Staff taps → sees order details → accepts → status updated
```

---

## ⚙️ Server Configuration

The app supports **one-tap switching** between:
- **Live:** `https://pizzaonerestaurant.com` (production)
- **Local:** `http://localhost/pizzaone` (XAMPP development)
- **Custom:** Any IP/URL (useful for same-WiFi tablet use)

---

## 📊 Order Status Workflow

```
pending → confirming → preparing → ready → delivered
                                        ↘ cancelled
```

Each transition is available as a **1-tap action button** on both the order card and detail screen.
