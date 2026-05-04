# Cache Manager

`CacheManager` adalah hybrid cache dua lapis: **memory** (instan, hilang saat app mati) dan **LocalStorage** (persisten lintas sesi). Mendukung TTL, force refresh, stale-while-revalidate, dan deduplication request yang concurrent.

---

## Struktur file

```
lib/core/services/caching/
└── cache_manager.dart   # CacheEntry + CacheManager
```

---

## Arsitektur dua lapis

```
get(key)
  │
  ├─▶ [1] Memory          — sync, instan
  │       hit & fresh    → return
  │       hit & stale    → SWR: return stale + revalidate background
  │       miss           → lanjut ke [2]
  │
  ├─▶ [2] LocalStorage    — sync read (SharedPreferences)
  │       hit & fresh    → promote ke memory, return
  │       hit & stale    → SWR: return stale + revalidate background
  │       miss           → lanjut ke [3]
  │
  └─▶ [3] Fetcher         — network / IO
          selesai        → simpan ke memory + storage, return
          concurrent     → dedupe: semua caller tunggu Future yang sama
```

---

## Registrasi di GetIt

`CacheManager` sudah didaftarkan di `locator.dart` dan diinjeksi dengan `LocalStorage`:

```dart
locator.registerLazySingleton(() => CacheManager(locator()));
```

Ambil instance dari locator:

```dart
final cache = locator<CacheManager>();
```

---

## Penggunaan dasar

**Tipe primitif** — String, int, bool, double tidak butuh `fromJson`/`toJson`:

```dart
final cache = locator<CacheManager>();

final username = await cache.get<String>(
  key: 'profile_username',
  maxAge: const Duration(minutes: 15),
  fetcher: () => userApi.getUsername(),
);
```

**Tipe objek** — wajib sertakan `fromJson` dan `toJson`:

```dart
final profile = await cache.get<UserProfile>(
  key: 'user_profile',
  maxAge: const Duration(minutes: 15),
  fetcher: () => userApi.getProfile(),
  fromJson: UserProfile.fromJson,
  toJson: (p) => p.toJson(),
);
```

---

## Parameter `get()`

| Parameter | Tipe | Default | Keterangan |
|---|---|---|---|
| `key` | `String` | — | Kunci unik cache |
| `fetcher` | `Future<T> Function()` | — | Sumber data (network/IO) |
| `maxAge` | `Duration?` | `null` | TTL; `null` = tidak pernah expired |
| `forceRefresh` | `bool` | `false` | Lewati kedua layer, langsung fetch |
| `staleWhileRevalidate` | `bool` | `false` | Return data lama, fetch baru di background |
| `fromJson` | `T Function(dynamic)?` | `null` | Deserialize dari storage |
| `toJson` | `dynamic Function(T)?` | `null` | Serialize ke storage |

---

## Stale-while-revalidate (SWR)

Cocok untuk data yang boleh tampil sedikit ketinggalan tapi harus tetap responsif:

```dart
final products = await cache.get<List<Product>>(
  key: 'home_products',
  maxAge: const Duration(minutes: 5),
  staleWhileRevalidate: true,   // tampil data lama dulu, update di background
  fetcher: () => productApi.getAll(),
  fromJson: (json) => (json as List).map(Product.fromJson).toList(),
  toJson: (list) => list.map((p) => p.toJson()).toList(),
);
```

---

## Force refresh

Paksa fetch ulang meski data cache masih fresh — berguna setelah user melakukan aksi mutasi:

```dart
await cache.get<UserProfile>(
  key: 'user_profile',
  forceRefresh: true,
  fetcher: () => userApi.getProfile(),
  fromJson: UserProfile.fromJson,
  toJson: (p) => p.toJson(),
);
```

---

## Invalidasi & pembersihan

```dart
final cache = locator<CacheManager>();

// Hapus dari memory saja (storage tetap ada)
cache.invalidate('user_profile');

// Hapus dari storage saja (memory tetap ada)
await cache.invalidatePersistent('user_profile');

// Bersihkan seluruh memory (storage tidak tersentuh)
cache.clearMemory();

// Bersihkan kedua layer sekaligus
await cache.clearAll();
```

Pola umum — invalidasi setelah mutasi berhasil:

```dart
Future<void> updateProfile(UserProfile updated) async {
  await userApi.updateProfile(updated);
  cache.invalidate('user_profile');
  await cache.invalidatePersistent('user_profile');
}
```

---

## Pola konsumsi di Repository

`CacheManager` tidak boleh dipanggil langsung dari Cubit atau Widget. Gunakan lewat Repository:

```dart
// lib/features/profile/data/repository/profile_repository.dart
class ProfileRepository {
  ProfileRepository(this._api, this._cache);

  final ProfileApi _api;
  final CacheManager _cache;

  static const _keyProfile = 'user_profile';

  Future<Result<UserProfile, AppError>> getProfile() async {
    try {
      final data = await _cache.get<UserProfile>(
        key: _keyProfile,
        maxAge: const Duration(minutes: 15),
        staleWhileRevalidate: true,
        fetcher: () => _api.getProfile(),
        fromJson: UserProfile.fromJson,
        toJson: (p) => p.toJson(),
      );
      return Result.success(data);
    } on AppException catch (e) {
      return Result.failure(e.toAppError());
    }
  }

  Future<void> invalidateProfile() async {
    _cache.invalidate(_keyProfile);
    await _cache.invalidatePersistent(_keyProfile);
  }
}
```

---

## Aturan

| Layer | Boleh | Tidak Boleh |
|---|---|---|
| Widget | Render state via `BlocBuilder` | Panggil `CacheManager` langsung |
| Cubit/Bloc | Panggil method Repository | Panggil `CacheManager` langsung |
| Repository | Gunakan `CacheManager.get()`, invalidasi | Tahu detail layer memory/storage |
| CacheManager | Cache saja | Tahu tentang domain/fitur apapun |
