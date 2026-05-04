# Socket Client

`SocketClient` adalah transport layer untuk koneksi WebSocket berbasis Socket.IO. Ia adalah singleton tanpa konfigurasi di constructor — URL diatur secara eksplisit sebelum connect, sehingga cocok untuk diregistrasi di GetIt dan dikonfigurasi saat runtime (misalnya setelah env config atau response API tersedia).

---

## Struktur file

```
lib/core/datasource/socket/
└── socket_client.dart   # transport layer Socket.IO
```

---

## Registrasi di GetIt

```dart
// lib/core/injection/locator.dart
sl.registerLazySingleton<SocketClient>(() => SocketClient());
```

---

## Lifecycle dengan Auth System

Socket hanya boleh aktif saat user sudah terautentikasi. Kendalikan connect/disconnect dari `AuthNotifier`:

```dart
class AuthNotifier extends ChangeNotifier {
  final SocketClient _socket = sl<SocketClient>();

  void _authenticate(String token) {
    _token = token;
    _isAuthenticated = true;

    _socket.connectWithToken(token); // CONNECT setelah auth

    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _token = null;
    _storage.remove(StorageKey.authToken);

    _socket.disconnect(); // DISCONNECT saat logout

    notifyListeners();
  }
}
```

| Kondisi | Action |
|---|---|
| Login sukses | `connectWithToken(token)` |
| Auto-login saat app start | `connectWithToken(token)` |
| Logout | `disconnect()` |
| Token expired (401) | `logout()` → otomatis `disconnect()` |
| App di-background *(opsional)* | `disconnect()` |
| App kembali foreground *(opsional)* | `reconnect()` |

---

## Reconnect

Auto-reconnect aktif secara otomatis saat koneksi terputus tak terduga (`onDisconnect` / `onConnectError`), dengan exponential delay (3s, 6s, 9s, ...) hingga 10 percobaan. `disconnect()` menonaktifkan auto-reconnect sepenuhnya. `reconnect()` tersedia untuk paksa reconnect manual (misalnya tombol "Coba Lagi").

---

## Pola Konsumsi per Fitur

`SocketClient` tidak boleh disentuh langsung oleh Cubit atau Widget. Setiap fitur membungkusnya dalam **Repository** yang meng-expose `Stream`:

```
SocketClient  (core — transport, singleton)
     │
     ▼
Repository   (feature — pasang listener, expose Stream)
     │
     ▼
Cubit/Bloc   (feature — subscribe Stream, emit state)
     │
     ▼
Widget       (UI — render state via BlocBuilder)
```

**Repository** — mendengarkan socket dan meneruskan data lewat `StreamController`:

```dart
// lib/features/chat/data/repository/chat_repository.dart
class ChatRepository {
  final SocketClient _socket = sl<SocketClient>();
  final _messageController = StreamController<ChatMessage>.broadcast();

  Stream<ChatMessage> get onMessage => _messageController.stream;

  void init() {
    _socket.on('new_message', (data) {
      _messageController.add(ChatMessage.fromJson(data as Map<String, dynamic>));
    });
  }

  void sendMessage(String roomId, String text) {
    _socket.emit('send_message', {'room_id': roomId, 'text': text});
  }

  void dispose() {
    _socket.off('new_message');
    _messageController.close();
  }
}
```

**Cubit** — subscribe ke stream repository, tidak menyentuh socket langsung:

```dart
// lib/features/chat/presentation/cubit/chat_cubit.dart
class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _repo = sl<ChatRepository>();
  StreamSubscription<ChatMessage>? _sub;

  ChatCubit() : super(ChatState.initial());

  void init() {
    _repo.init();
    _sub = _repo.onMessage.listen((message) {
      emit(state.copyWith(messages: [...state.messages, message]));
    });
  }

  void sendMessage(String roomId, String text) {
    _repo.sendMessage(roomId, text);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _repo.dispose();
    return super.close();
  }
}
```

---

## Fitur Global vs Per Halaman

Beberapa fitur socket hidup sepanjang sesi (notifikasi real-time, presence), sebagian lain hanya aktif saat halaman tertentu dibuka.

| Repository | `init()` dipanggil | `dispose()` dipanggil |
|---|---|---|
| `NotificationRepository` | Setelah login / auto-login | Saat logout |
| `PresenceRepository` | Setelah login / auto-login | Saat logout |
| `ChatRepository` | Saat halaman chat dibuka | Saat halaman chat ditutup |

Repository global di-init dari `AuthNotifier` setelah `connectWithToken()`:

```dart
void _authenticate(String token) {
  _socket.connectWithToken(token);

  sl<NotificationRepository>().init();
  sl<PresenceRepository>().init();

  // ...
}

void logout() {
  sl<NotificationRepository>().dispose();
  sl<PresenceRepository>().dispose();

  _socket.disconnect();
  // ...
}
```

Cubit untuk fitur global dipasang di root widget (di atas `MaterialApp`) agar tetap hidup sepanjang sesi:

```dart
// app.dart
BlocProvider(
  create: (_) => sl<NotificationCubit>()..init(),
  child: MaterialApp.router(...),
)
```

---

## Satu Socket, Banyak Repository

`SocketClient` adalah singleton. Setiap repository mendaftarkan listener untuk event miliknya sendiri — tidak ada konflik:

```
SocketClient (singleton)
 ├── ChatRepository         → listen 'new_message', 'typing'
 ├── NotificationRepository → listen 'notification'
 └── PresenceRepository     → listen 'user_online', 'user_offline'
```

---

## Aturan

| Layer | Boleh | Tidak Boleh |
|---|---|---|
| Widget | Subscribe `BlocBuilder` | Sentuh socket atau repository |
| Cubit/Bloc | Subscribe stream dari repository | Panggil `socket.on()` langsung |
| Repository | Pasang listener, expose `Stream` | Emit state UI |
| SocketClient | Transport saja | Tahu tentang domain/fitur apapun |
