# Template App

A Flutter starter template with clean architecture, authentication scaffolding, and reusable core infrastructure. Targets Android, iOS, Web, Windows, macOS, and Linux.

---

## Tech Stack

| Package                           | Purpose                        |
| --------------------------------- | ------------------------------ |
| `flutter_bloc` / `hydrated_bloc`  | State management + persistence |
| `go_router` + `go_router_builder` | Declarative routing + codegen  |
| `get_it`                          | Dependency injection           |
| `dio` + `pretty_dio_logger`       | HTTP client + request logging  |
| `connectivity_plus`               | Network connectivity detection |
| `shared_preferences`              | Local key-value storage        |
| `socket_io_client`                | WebSocket / Socket.IO          |
| `permission_handler`              | Runtime permissions            |
| `cached_network_image`            | Image caching                  |
| `shimmer`                         | Loading skeleton UI            |

---

## Architecture

```
lib/
├── main.dart
├── core/
│   ├── constants/       # Auto-generated asset paths
│   ├── datasource/      # DioClient, LocalStorage, SocketClient
│   ├── debug/           # Logger (no-op in release)
│   ├── enums/           # RequestState
│   ├── errors/          # AppError, AppException, and subtypes
│   ├── extensions/      # DateTime, BuildContext
│   ├── injection/       # GetIt locator
│   ├── services/        # NotificationService, FirebaseMessagingService, CacheManager
│   └── utilities/       # Result<S,E>, Debouncer
├── modules/
│   ├── app.dart
│   ├── auth/            # AuthNotifier (ChangeNotifier)
│   └── main/            # Bottom-tab shell
├── router/              # GoRouter config + generated routes
└── widget/              # Shared UI components
```

**Data flow:** `Repository → UseCase → Cubit/Bloc → UI`

**State management:** BLoC/Cubit for features; `AuthNotifier` (ChangeNotifier) for auth + router refresh.

**Error handling:** All data operations return `Result<S, AppError>` — never throw across layer boundaries.

---

## Getting Started

```bash
# Run
flutter run

# Generate code (routes, assets)
dart run build_runner build --delete-conflicting-outputs

# Run tests
flutter test

# Build APK
flutter build apk --release
```

---

## Service Documentation

Detailed guides for the core services are in the [`docs/`](docs/) folder:

| Document                                     | Description                                                              |
| -------------------------------------------- | ------------------------------------------------------------------------ |
| [Notification Service](docs/notification.md) | Local notifications + FCM push, dispatcher pattern, adding new handlers  |
| [Socket Client](docs/socket.md)              | Socket.IO transport, lifecycle with auth, per-feature repository pattern |
| [Cache Manager](docs/cache.md)               | Two-layer memory/storage cache, TTL, SWR, force refresh, invalidation    |
