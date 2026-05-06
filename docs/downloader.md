# Download Service

`DownloadService` adalah wrapper di atas plugin [`background_downloader`](https://pub.dev/packages/background_downloader) untuk mengunduh file di background dengan dukungan notifikasi sistem, progress callback, dan pemindahan otomatis ke shared storage (Gallery / Downloads). API-nya plugin-agnostic — consumer tidak perlu import `background_downloader`.

---

## Struktur file

```
lib/core/services/downloader/
└── download_service.dart   # DownloadService + model + enum
```

Berkas tunggal berisi:

| Tipe | Peran |
|---|---|
| `DownloadFileType` | Kategori file (`image`, `video`, `document`) — menentukan tujuan shared storage |
| `DownloadStatus` | Status unduhan domain (mirror `TaskStatus` plugin) |
| `DownloadFileRequest` | Item dalam batch (url + filename + type) |
| `DownloadResult` | Hasil per file (filename, status, filePath) |
| `DownloadBatchResult` | Agregat batch (`succeeded` / `failed` list, counter) |
| `DownloadService` | Service utama |

---

## Fitur

- **Single download** — `downloadFile(url, filename, type)` dengan callback `onProgress(double)` dan `onStatus(DownloadStatus)`.
- **Batch download** — `downloadBatch([requests])` dengan callback agregat `onBatchProgress(succeeded, failed)`.
- **Auto move ke shared storage** — selesai download → otomatis pindah sesuai `FileType`:
  - `image` → `SharedStorage.images` (Gallery)
  - `video` → `SharedStorage.video` (Gallery)
  - `document` → Android: `SharedStorage.downloads`, iOS: tetap di `applicationDocuments`
- **Notifikasi sistem** — Android: progress bar + filename, iOS: complete/error sederhana. Bisa dimatikan via `showNotification: false`.
- **Defensive callbacks** — exception dari callback user di-log, tidak meng-crash flow download.
- **Lifecycle eksplisit** — `init()` / `dispose()` untuk subscription stream global.

---

## Registrasi di GetIt

Sudah didaftarkan di `lib/injection/locator.dart`. `init()` di-await sebelum register agar listener stream sudah terpasang sebelum download apa pun dipicu.

```dart
final downloadService = DownloadService();
await downloadService.init();
locator.registerSingleton(downloadService);
```

Ambil instance:

```dart
final downloader = locator<DownloadService>();
```

---

## Single download

```dart
final downloader = locator<DownloadService>();

final result = await downloader.downloadFile(
  'https://example.com/photo.jpg',
  'photo.jpg',
  DownloadFileType.image,
  onProgress: (p) => debugPrint('Progress: ${(p * 100).toInt()}%'),
  onStatus: (s) => debugPrint('Status: ${s.name}'),
);

result.when(
  success: (data) {
    // data.filePath berisi path final di shared storage (atau null untuk iOS doc)
    debugPrint('Saved to: ${data.filePath}');
  },
  failure: (err) => debugPrint('Failed: ${err.message}'),
);
```

---

## Batch download

```dart
final result = await downloader.downloadBatch(
  [
    DownloadFileRequest(
      url: 'https://example.com/a.jpg',
      filename: 'a.jpg',
      type: DownloadFileType.image,
    ),
    DownloadFileRequest(
      url: 'https://example.com/b.mp4',
      filename: 'b.mp4',
      type: DownloadFileType.video,
    ),
    DownloadFileRequest(
      url: 'https://example.com/c.pdf',
      filename: 'c.pdf',
      type: DownloadFileType.document,
    ),
  ],
  onBatchProgress: (ok, failed) {
    debugPrint('Progress batch: $ok ok, $failed failed');
  },
);

result.when(
  success: (batch) {
    debugPrint('${batch.numSucceeded}/${batch.total} berhasil');
    for (final f in batch.failed) {
      debugPrint('Gagal: ${f.filename} (${f.status.name})');
    }
  },
  failure: (err) => debugPrint(err.message),
);
```

Penting: `Result.success(batch)` dipakai bahkan saat sebagian (atau semua) file gagal. Cek `batch.hasFailures` / `batch.failed` untuk per-file inspection. `Result.failure` hanya saat error level batch (mis. validasi, exception plugin).

---

## Status mapping

`DownloadStatus` adalah enum domain yang 1:1 dengan plugin status:

| DownloadStatus | Arti |
|---|---|
| `enqueued` | Sudah masuk antrian, belum jalan |
| `running` | Sedang download |
| `complete` | Selesai sukses |
| `notFound` | HTTP 404 |
| `failed` | Gagal (network / IO / dll) |
| `canceled` | Dibatalkan |
| `paused` | Terjeda |
| `waitingToRetry` | Menunggu retry otomatis |

Hanya `complete` yang dianggap sukses. Selain itu → masuk ke `failed` list di batch atau `Result.failure` di single download.

---

## Tujuan storage per `FileType`

| FileType | Android | iOS |
|---|---|---|
| `image` | `SharedStorage.images` (Gallery) | `SharedStorage.images` (Photos) |
| `video` | `SharedStorage.video` (Gallery) | `SharedStorage.video` (Photos) |
| `document` | `SharedStorage.downloads` | Tetap di `BaseDirectory.applicationDocuments` (sandbox app) |

> iOS tidak punya konsep "Downloads" publik. File dokumen tetap di sandbox; untuk dishare/dibuka, gunakan `share_plus` atau `open_filex`.

---

## Notifikasi

Default `showNotification: true`.

**Android** — running notification dengan progress bar, body `"<filename>\n{progress}"`. Notifikasi complete/error setelah selesai.
**iOS** — hanya notifikasi complete / error (iOS tidak support running progress bar untuk background download).

Matikan notifikasi (mis. untuk download silent / preload):

```dart
await downloader.downloadFile(url, name, type, showNotification: false);
```

---

## Lifecycle

```dart
// Saat startup app (sudah di-handle locator.dart)
await downloader.init();

// Saat shutdown/teardown (opsional, mis. di test atau hot-reload tooling)
await downloader.dispose();
```

`init()` aman dipanggil ulang — setelah inisialisasi pertama, panggilan kedua di-skip dengan log warning.

---

## Study case

### 1. Save photo from chat ke gallery

```dart
final r = await downloader.downloadFile(
  message.imageUrl,
  'chat_${message.id}.jpg',
  DownloadFileType.image,
);
r.when(
  success: (d) => showSnackBar('Tersimpan di galeri'),
  failure: (e) => showSnackBar(e.message),
);
```

### 2. Bulk download lampiran tiket

```dart
final reqs = ticket.attachments.map((a) => DownloadFileRequest(
  url: a.url,
  filename: a.name,
  type: DownloadFileType.document,
)).toList();

final r = await downloader.downloadBatch(reqs);
r.when(
  success: (b) {
    if (b.hasFailures) {
      showDialog('${b.numFailed} file gagal diunduh.');
    } else {
      showSnackBar('Semua file berhasil diunduh');
    }
  },
  failure: (e) => showSnackBar(e.message),
);
```

### 3. Background preload tanpa notifikasi

```dart
unawaited(downloader.downloadFile(
  catalog.thumbnailUrl,
  'thumb_${catalog.id}.jpg',
  DownloadFileType.image,
  showNotification: false,
));
```

---

## Permission

Plugin meng-handle sebagian besar permission, tapi pastikan:

- **Android 13+**: tambahkan `POST_NOTIFICATIONS` di `AndroidManifest.xml` dan minta runtime permission via `permission_handler` sebelum download dengan notifikasi.
- **iOS**: notification permission sudah diminta otomatis oleh plugin saat pertama kali notifikasi muncul — atau panggil `FileDownloader().permissions.request(PermissionType.notifications)` lebih awal.
- **Storage**: Android scoped storage (≥ Android 10) sudah otomatis lewat `MediaStore` ke folder yang sesuai. Tidak perlu `WRITE_EXTERNAL_STORAGE` untuk image/video/downloads.

---

## Best practice

- Selalu dispatch download dari **Repository** atau **Cubit**, jangan dari widget.
- Pakai `unawaited(...)` kalau memang fire-and-forget — jangan biarkan future menggantung tanpa diproses.
- Validasi URL & filename di sisi caller; service hanya menolak empty string.
- Untuk batch besar, batasi jumlah request paralel (mis. ≤ 10) — plugin tidak rate-limit otomatis.
- Tampilkan progress di UI via `Cubit` state, bukan dengan `setState` langsung dari callback.
- Setelah dapat `filePath`, simpan ke domain (mis. cache attachment lokal) — jangan re-download untuk view yang sama.

---

## Batasan

- **Tidak ada cancellation API** di service ini. Untuk dukung cancel, perlu redesign signature (mis. return handle/`taskId`). Plugin underlying support `cancelTasksWithIds`.
- **Tidak ada resume manual** — plugin auto-retry, tapi tidak ada API untuk pause/resume manual dari service ini.
- **Filename harus unik per session** — kalau dua download paralel pakai filename sama, file akan saling timpa di staging directory plugin.
- **Tidak ada overwrite check** — kalau di shared storage sudah ada file dengan nama sama, plugin akan rename otomatis (mis. `photo (1).jpg`). filePath yang di-return mengikuti hasil rename.
- **`onBatchProgress` bukan progress fraksi** — callback dipanggil setiap kali satu task selesai, parameter berisi count succeeded/failed terkini, bukan persentase keseluruhan.
- **iOS document tidak punya filePath publik** — `filePath` hasil download document di iOS mengarah ke sandbox, bukan lokasi yang bisa diakses user dari Files app secara default.

---

## Aturan

| Layer | Boleh | Tidak Boleh |
|---|---|---|
| Widget | Render progress via `BlocBuilder` | Panggil `DownloadService` langsung |
| Cubit/Bloc | Trigger download, expose state | Tahu detail `TaskStatus` plugin |
| Repository | Pakai `DownloadService`, mapping ke domain | Bypass service, pakai `FileDownloader()` langsung |
| DownloadService | Wrap plugin, mapping types | Tahu domain bisnis (chat, ticket, dll) |

---

## Yang harus & jangan dilakukan

**LAKUKAN**

- Pakai `DownloadFileType` yang tepat — salah pilih = file ke folder yang salah.
- Tangani `Result.failure` di UI dengan pesan ramah dari `AppError.message`.
- Pakai `batch.failed` untuk feedback parsial (jangan anggap batch all-or-nothing).
- Filter status di `onStatus` kalau hanya butuh state tertentu (mis. `running` untuk progress UI).

**JANGAN**

- Jangan import `package:background_downloader/...` di luar service ini — pakai `DownloadStatus`, `DownloadResult` saja.
- Jangan panggil `init()` manual di tempat lain — sudah di-handle locator.
- Jangan throw dari dalam `onProgress` / `onStatus` — sudah dibungkus try-catch tapi tetap log noise yang tidak perlu.
- Jangan asumsikan `filePath` selalu ada — di iOS document, hasilnya path sandbox; bisa juga `null` kalau move ke shared storage gagal.
- Jangan andalkan `_handleGlobalUpdate` untuk logic — itu sekedar log; semua state per-call ada di callback.
