# Firebase Remote Config Service

`RemoteConfigService` menyediakan akses terpusat ke nilai konfigurasi yang dikelola dari Firebase Console — tanpa perlu merilis versi app baru untuk mengubah perilaku fitur.

---

## Struktur file

```
lib/core/services/
└── firebase/
    └── remote_config_service.dart   # service + RemoteConfigKey constants
```

---

## Cara kerja

```
App startup
  └─▶ initLocator()
        └─▶ RemoteConfigService.initialize()
              ├─▶ setDefaults(_defaults)   ← nilai fallback jika fetch gagal
              └─▶ fetchAndActivate()       ← ambil nilai terbaru dari Firebase

Di dalam fitur
  └─▶ locator<RemoteConfigService>().getString(RemoteConfigKey.xxx)
```

Nilai yang dipakai dipilih dengan prioritas berikut (tertinggi ke terendah):

1. **Fetched & activated** — nilai dari Firebase Console yang sudah berhasil diambil.
2. **Cached** — nilai fetch terakhir yang tersimpan di device (fetch gagal, app offline).
3. **Default** — nilai dari `_defaults` di dalam service (fetch belum pernah berhasil).

> **Interval fetch:** Di release mode, fetch dibatasi **1 jam sekali** agar tidak throttle oleh Firebase. Di debug mode, interval diset ke 0 sehingga setiap `fetchAndActivate()` selalu hit server.

---

## Setup awal

**1. Firebase** — pastikan `Firebase.initializeApp()` sudah dipanggil di `main.dart` sebelum `initLocator()`:

```dart
// lib/main.dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
await initLocator();
```

**2. Firebase Console** — buka **Remote Config** di Firebase Console, lalu tambahkan parameter beserta nilai default-nya di sana. Nilai di console akan menimpa default lokal setelah fetch berhasil.

---

## Menambah parameter baru

Menambah parameter baru butuh **3 langkah**.

**Langkah 1** — Tambah konstanta key di `RemoteConfigKey`:

```dart
// lib/core/services/firebase/remote_config_service.dart
abstract final class RemoteConfigKey {
  static const String forceUpdateVersion = 'force_update_version';
  static const String maintenanceMode    = 'maintenance_mode';
  static const String maxUploadSizeMb    = 'max_upload_size_mb';
}
```

**Langkah 2** — Tambah nilai default di `_defaults` (wajib ada agar tidak crash saat offline):

```dart
static const Map<String, dynamic> _defaults = {
  RemoteConfigKey.forceUpdateVersion: '0.0.0',
  RemoteConfigKey.maintenanceMode:    false,
  RemoteConfigKey.maxUploadSizeMb:    10,
};
```

**Langkah 3** — Tambahkan parameter yang sama di **Firebase Console → Remote Config**.  
Nilai di console harus cocok tipenya dengan default lokal.

---

## Membaca nilai

Ambil service via `locator`, lalu gunakan getter yang sesuai tipe parameter:

```dart
final rc = locator<RemoteConfigService>();

// String
final minVersion = rc.getString(RemoteConfigKey.forceUpdateVersion);

// Bool
final isMaintenance = rc.getBool(RemoteConfigKey.maintenanceMode);

// Int
final maxMb = rc.getInt(RemoteConfigKey.maxUploadSizeMb);

// Double
final discountRate = rc.getDouble('discount_rate');
```

Jika key tidak ditemukan di defaults maupun Firebase, getter mengembalikan nilai kosong sesuai tipe (`''`, `false`, `0`, `0.0`) — **tidak melempar exception**.

---

## Refresh nilai di tengah sesi

`initialize()` sudah fetch saat startup. Gunakan `fetchAndActivate()` untuk memaksa refresh manual, misalnya saat user membuka app dari background setelah lama:

```dart
final rc = locator<RemoteConfigService>();

final updated = await rc.fetchAndActivate();
if (updated) {
  // Nilai baru sudah aktif — perbarui UI jika perlu
  final isMaintenance = rc.getBool(RemoteConfigKey.maintenanceMode);
  if (isMaintenance) _showMaintenanceBanner();
}
```

> `fetchAndActivate()` mengembalikan `true` jika ada nilai baru yang diaktifkan, `false` jika nilai sama dengan sebelumnya atau fetch gagal.

---

## Contoh penggunaan: force update

Cek versi minimum yang diizinkan beroperasi. Jalankan pengecekan ini saat app resume atau di splash screen:

```dart
// lib/features/update/check_update_service.dart
import 'package:package_info_plus/package_info_plus.dart';

class CheckUpdateService {
  final RemoteConfigService _rc;
  CheckUpdateService(this._rc);

  Future<bool> isForceUpdateRequired() async {
    final info    = await PackageInfo.fromPlatform();
    final current = info.version;                                    // e.g. '2.3.1'
    final minimum = _rc.getString(RemoteConfigKey.forceUpdateVersion); // e.g. '2.4.0'

    return _isLower(current, minimum);
  }

  bool _isLower(String current, String minimum) {
    final c = current.split('.').map(int.parse).toList();
    final m = minimum.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      if (c[i] < m[i]) return true;
      if (c[i] > m[i]) return false;
    }
    return false;
  }
}
```

---

## Contoh penggunaan: maintenance mode

Tampilkan halaman pemeliharaan sebelum masuk ke main flow:

```dart
// di splash cubit / app bloc
final isMaintenance = locator<RemoteConfigService>()
    .getBool(RemoteConfigKey.maintenanceMode);

if (isMaintenance) {
  context.go('/maintenance');
  return;
}
```

---

## Metadata nilai (sumber & waktu fetch)

Gunakan `getValue()` jika kamu perlu tahu apakah nilai berasal dari remote atau default:

```dart
final value = rc.getValue(RemoteConfigKey.maintenanceMode);

print(value.asString());                  // nilai sebagai String
print(value.source);                      // ValueSource.remote / .default / .static
print(value.fetchTime);                   // DateTime fetch terakhir (jika remote)
```

Berguna untuk debugging — memastikan nilai yang aktif benar-benar dari Firebase, bukan fallback.

---

## Aturan penting

| Aturan | Alasan |
|---|---|
| Selalu deklarasikan key di `RemoteConfigKey` | Menghindari typo dan memudahkan pencarian referensi |
| Selalu tambahkan default di `_defaults` | Nilai wajib ada agar getter tidak mengembalikan string kosong tak terduga saat offline |
| Nilai default lokal harus cocok tipenya dengan nilai di Firebase Console | Tipe tidak konsisten menyebabkan `getBool` / `getInt` mengembalikan nilai salah |
| Jangan akses `FirebaseRemoteConfig.instance` langsung di luar service | Semua akses harus melalui `RemoteConfigService` agar testable dan mudah di-mock |