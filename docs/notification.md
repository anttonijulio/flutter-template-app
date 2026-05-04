# Notification Service

Arsitektur notifikasi terdiri dari dua layer yang bekerja bersama:

| Service | Package | Tanggung jawab |
|---|---|---|
| `NotificationService` | `flutter_local_notifications` | Tampilkan notifikasi di device |
| `FirebaseMessagingService` | `firebase_messaging` | Terima push notification dari server |

Keduanya terhubung melalui `NotificationDispatcher` sebagai single entry point untuk semua aksi tap.

---

## Struktur file

```
lib/core/services/
├── firebase/
│   ├── firebase_background.dart        # top-level handler background isolate FCM
│   └── firebase_messaging_service.dart # terima pesan FCM, token, topic
├── notification/
│   ├── notification_background.dart    # top-level handler background isolate lokal
│   ├── notification_dispatcher.dart    # registry + routing ke feature handler
│   ├── notification_payload.dart       # model payload + NotificationType constants
│   └── notification_service.dart       # tampilkan notifikasi lokal
└── injection/
    └── locator.dart
```

---

## Alur kerja

```
Notifikasi lokal (flutter_local_notifications)
─────────────────────────────────────────────
  Foreground tap
    └─▶ NotificationService → NotificationDispatcher → Handler

  Background tap (Android)
    └─▶ onBackgroundNotificationResponse()  [isolate terpisah]
          └─▶ simpan payload ke SharedPreferences
                └─▶ app resume → App._consumePendingNotification()
                      └─▶ NotificationDispatcher → Handler

  Terminated tap
    └─▶ app cold start → getNotificationAppLaunchDetails()
          └─▶ App._consumePendingNotification()
                └─▶ NotificationDispatcher → Handler

Push notification (firebase_messaging)
───────────────────────────────────────
  Foreground message (notification + data)
    └─▶ FirebaseMessagingService → NotificationService.show()
          └─▶ user tap → NotificationDispatcher → Handler

  Foreground message (data-only / silent)
    └─▶ FirebaseMessagingService → NotificationDispatcher → Handler  [langsung]

  Background tap
    └─▶ onMessageOpenedApp → NotificationDispatcher → Handler

  Terminated tap
    └─▶ app cold start → getInitialMessage()
          └─▶ App._consumePendingNotification()
                └─▶ NotificationDispatcher → Handler

  Background data-only
    └─▶ onFirebaseBackgroundMessage()  [isolate terpisah]
          └─▶ simpan payload ke SharedPreferences
                └─▶ app resume → App._consumePendingNotification()
                      └─▶ NotificationDispatcher → Handler
```

> **Catatan:** Handler selalu berjalan di main isolate. Background dan terminated hanya menunda eksekusi — handler tetap jalan ketika app sudah terbuka.

---

## Setup awal

**1. Firebase** — jalankan `flutterfire configure` untuk generate `firebase_options.dart`, lalu update `main.dart`:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform, // dari firebase_options.dart
);
```

**2. Izin notifikasi** — minta izin satu kali, biasanya di halaman onboarding:

```dart
await locator<NotificationService>().requestPermission();
```

---

## Menambah fitur baru

Menambah fitur baru butuh **2 langkah** — tidak ada kode lama yang diubah.

**Langkah 1** — Tambah konstanta tipe di `notification_payload.dart`:

```dart
abstract final class NotificationType {
  static const chat  = 'chat';
  static const order = 'order';  // ← tambah di sini
}
```

**Langkah 2** — Buat handler di folder fitur:

```dart
// lib/features/order/notification/order_notification_handler.dart
class OrderNotificationHandler implements NotificationHandler {
  const OrderNotificationHandler(this._router);

  final AppRouter _router;

  @override
  String get type => NotificationType.order;

  @override
  void handle(NotificationPayload payload) {
    final orderId = payload.data['order_id'] as String?;
    if (orderId == null) return;

    // Gunakan typed route dari go_router_builder — .location tidak butuh context
    _router.router.go(OrderRoute(orderId: orderId).location);
  }
}
```

**Langkah 3** — Daftarkan di `locator.dart`:

```dart
dispatcher.register(OrderNotificationHandler(locator()));
```

Handler bisa melakukan lebih dari sekadar navigasi — trigger cubit, update state, dll:

```dart
@override
void handle(NotificationPayload payload) {
  final promoId = payload.data['promo_id'] as String?;
  locator<PromoCubit>().loadPromo(promoId);
}
```

---

## Mengirim notifikasi lokal

Payload **wajib** berisi `NotificationPayload` agar dispatcher bisa meneruskan ke handler yang benar.

```dart
final notif = locator<NotificationService>();

// Notifikasi sederhana
await notif.show(
  id: 1,
  title: 'Pesan baru',
  body: 'John: Halo!',
  payload: NotificationPayload(
    type: NotificationType.chat,
    data: {'room_id': 'abc123'},
  ).encode(),
);

// Notifikasi dengan teks panjang (expanded di Android)
await notif.showBigText(
  id: 2,
  title: 'Update pesanan',
  body: 'Pesanan #99 sedang dikirim',
  bigText: 'Pesanan #99 sedang dalam perjalanan. Estimasi tiba pukul 15.00 WIB.',
  payload: NotificationPayload(
    type: NotificationType.order,
    data: {'order_id': '99'},
  ).encode(),
);

// Cancel
await notif.cancel(1);
await notif.cancelAll();
```

---

## Format payload FCM (server-side)

Server harus menyertakan field `type` di dalam `data` agar dispatcher bisa meneruskan ke handler yang tepat.

**Notification message** (FCM tampilkan notifikasi otomatis saat background):

```json
{
  "to": "<fcm_token>",
  "notification": {
    "title": "Pesan baru",
    "body": "John: Halo!"
  },
  "data": {
    "type": "chat",
    "room_id": "abc123"
  }
}
```

**Data-only message** (silent push, tidak ada notifikasi UI):

```json
{
  "to": "<fcm_token>",
  "data": {
    "type": "order",
    "order_id": "99"
  }
}
```

---

## FCM token

Kirim token ke backend setelah user login, dan perbarui setiap kali token di-rotate:

```dart
final fcm = locator<FirebaseMessagingService>();

// Ambil token saat login
final token = await fcm.getToken();
await myApi.updateFcmToken(token);

// Perbarui token jika di-rotate oleh FCM
fcm.onTokenRefresh.listen((newToken) {
  myApi.updateFcmToken(newToken);
});

// Topic-based messaging (broadcast ke grup user)
await fcm.subscribeToTopic('promo');
await fcm.unsubscribeFromTopic('promo');
```

---

## Aturan ID notifikasi lokal

ID harus unik per notifikasi aktif. Definisikan sebagai konstanta agar tidak bentrok:

```dart
// lib/core/services/notification/notification_ids.dart
abstract final class NotificationId {
  static const chat  = 100;
  static const order = 200;
  static const promo = 300;
}
```

Untuk notifikasi dinamis (banyak item berbeda), gunakan hash dari entity ID:

```dart
id: 'room_abc123'.hashCode,
```
