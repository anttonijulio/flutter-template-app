# Template App

> **Disclaimer**
>
> Repository ini adalah **template pribadi penulis**. Setiap service layer yang ada di sini merupakan cerminan dari study case nyata yang pernah penulis alami selama mengerjakan proyek — bukan arsitektur umum, bukan best practice universal, dan bukan rujukan resmi.
>
> Penulis **tidak merekomendasikan** template ini untuk dipakai orang lain. Jika Anda menemukannya dan tergerak menggunakannya, lakukan dengan kesadaran penuh bahwa keputusan desain di sini sangat opinionated dan terikat pada konteks penulis. Tidak ada jaminan dukungan, kompatibilitas, atau dokumentasi yang ramah untuk pengguna luar.

---

Flutter starter template dengan clean architecture, scaffolding autentikasi, dan core infrastructure yang reusable. Mendukung Android, iOS.

---

## Tech Stack

| Package                           | Kegunaan                       |
| --------------------------------- | ------------------------------ |
| `flutter_bloc` / `hydrated_bloc`  | State management + persistensi |
| `go_router` + `go_router_builder` | Declarative routing + codegen  |
| `get_it`                          | Dependency injection           |
| `dio` + `pretty_dio_logger`       | HTTP client + logging request  |
| `connectivity_plus`               | Deteksi konektivitas jaringan  |
| `shared_preferences`              | Penyimpanan key-value lokal    |
| `socket_io_client`                | WebSocket / Socket.IO          |
| `permission_handler`              | Runtime permission             |
| `cached_network_image`            | Caching gambar                 |
| `shimmer`                         | Skeleton UI saat loading       |

---

## Arsitektur

```
lib/
├── main.dart
├── core/
│   ├── constants/       # Path asset auto-generated
│   ├── datasource/      # DioClient, LocalStorage, SocketClient
│   ├── debug/           # Logger (no-op di release)
│   ├── enums/           # RequestState
│   ├── errors/          # AppError, AppException, dan turunannya
│   ├── extensions/      # DateTime, BuildContext
│   ├── injection/       # GetIt locator
│   ├── services/        # NotificationService, FirebaseMessagingService, CacheManager
│   └── utilities/       # Result<S,E>, Debouncer
├── modules/
│   ├── app.dart
│   ├── auth/            # AuthNotifier (ChangeNotifier)
│   └── main/            # Shell bottom-tab
├── router/              # Konfigurasi GoRouter + generated routes
└── widget/              # Komponen UI bersama
```

**Data flow:** `Repository → UseCase → Cubit/Bloc → UI`

**State management:** BLoC/Cubit untuk fitur; `AuthNotifier` (ChangeNotifier) untuk auth + router refresh.

**Error handling:** Semua operasi data mengembalikan `Result<S, AppError>` — tidak pernah melempar exception lintas layer.

---

## Memulai

```bash
# Jalankan
flutter run

# Generate code (routes, assets)
dart run build_runner build --delete-conflicting-outputs

# Jalankan test
flutter test

# Build APK
flutter build apk --release
```

---

## Dokumentasi Service

Panduan detail untuk setiap core service ada di folder [`docs/`](docs/):

| Dokumen                                                  | Deskripsi                                                                                                           |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| [Notification Service](docs/notification.md)             | Local notification + FCM push, pola dispatcher, cara menambah handler baru                                          |
| [Socket Client](docs/socket.md)                          | Transport Socket.IO, lifecycle dengan auth, pola repository per fitur                                               |
| [Cache Manager](docs/cache.md)                           | Cache dua-lapis memory/storage, TTL, SWR, force refresh, invalidasi                                                 |
| [Remote Config](docs/remote_config.md)                   | Firebase Remote Config, menambah parameter, force update, maintenance mode                                          |
| [DioClient & AppApiClient](docs/dio_client.md)           | Setup HTTP client, multi base URL, interceptors, konsumsi di datasource                                             |
| [Result<S, E>](docs/result.md)                           | Sealed return type untuk operasi data: membuat, mengambil value, transformasi, dan pola per layer                   |
| [LocationServiceHelper](docs/location_service_helper.md) | Dialog GPS native via Play Services (Android) tanpa redirect ke Settings; setup, konflik native, batasan            |
| [Download Service](docs/downloader.md)                   | Wrapper `background_downloader`: single & batch download, auto move ke shared storage, notifikasi sistem, lifecycle |
