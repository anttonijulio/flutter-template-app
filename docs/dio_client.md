# DioClient & AppApiClient

`DioClient` adalah low-level HTTP wrapper berbasis Dio. Ia menangani connectivity check, error mapping, dan logging — tidak tahu soal response schema apapun. `AppApiClient` adalah thin wrapper di atasnya khusus untuk backend utama yang memetakan response ke `ResponseDto<T>`.

---

## Struktur file

```
lib/core/services/datasource/api/
├── dio_client.dart        # Low-level HTTP wrapper, return Response<dynamic>
├── app_api_client.dart    # Wrapper backend utama, return ResponseDto<T>
├── auth_interceptor.dart  # Inject Bearer token dari AuthNotifier
└── response_dto.dart      # Schema response backend utama
```

---

## Arsitektur

```
DioClient          → connectivity check, error mapping, PrettyDioLogger
     │
     ├── AuthInterceptor     ─┐ dirakit di locator,
     └── RefreshInterceptor  ─┘ hanya untuk mainApi
     │
AppApiClient       → wrap DioClient, map Response → ResponseDto<T>
```

`DioClient` tidak tahu tentang `AuthNotifier`, `ResponseDto`, atau skema apapun. Interceptor dan response mapping adalah urusan caller.

---

## Registrasi di locator

### Instance default (backend utama)

```dart
// lib/injection/locator.dart
locator.registerLazySingleton(() => Connectivity());

locator.registerLazySingleton(
  () => DioClient(
    'https://api.main.com',
    locator(),
    interceptors: [AuthInterceptor(locator())],
  ),
  instanceName: 'mainApi',
);

locator.registerLazySingleton(
  () => AppApiClient(locator(instanceName: 'mainApi')),
);
```

### Menambah instance untuk base URL berbeda

```dart
// Tanpa interceptors — auth token tidak dikirim ke API eksternal
locator.registerLazySingleton(
  () => DioClient('https://maps.googleapis.com', locator()),
  instanceName: 'mapsApi',
);

// Dengan interceptor custom jika diperlukan
locator.registerLazySingleton(
  () => DioClient(
    'https://api.partner.com',
    locator(),
    interceptors: [ApiKeyInterceptor('secret-key')],
  ),
  instanceName: 'partnerApi',
);
```

> Setiap `DioClient` berbagi satu instance `Connectivity` yang sama dari GetIt.

---

## Menambah Interceptor

Buat class yang extends `Interceptor` dari package `dio`, lalu rakit di locator:

```dart
// lib/core/services/datasource/api/refresh_token_interceptor.dart
class RefreshTokenInterceptor extends Interceptor {
  final AuthNotifier _authNotifier;
  RefreshTokenInterceptor(this._authNotifier);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // handle refresh token logic
    }
    handler.next(err);
  }
}
```

```dart
// locator.dart — tambahkan ke mainApi
interceptors: [
  AuthInterceptor(locator()),
  RefreshTokenInterceptor(locator()),
],
```

Urutan interceptor penting: `AuthInterceptor` harus sebelum `RefreshTokenInterceptor` agar token sudah ter-inject saat refresh diperlukan.

---

## Konsumsi di Datasource

### Backend utama — inject `AppApiClient`

`AppApiClient` return `ResponseDto<T>`. Parsing `data` dilakukan di datasource dengan `fromJson`.

```dart
// lib/features/auth/datasource/auth_remote_datasource.dart
class AuthRemoteDatasource {
  final AppApiClient _client;
  AuthRemoteDatasource(this._client);

  Future<AuthData> login(String email, String password) async {
    final res = await _client.post<Map<String, dynamic>>(
      endpoint: '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthData.fromJson(res.data!);
  }
}
```

Registrasi di locator:

```dart
locator.registerLazySingleton(
  () => AuthRemoteDatasource(locator()),
);
```

### API eksternal — inject `DioClient` dengan instanceName

`DioClient` return `Response<dynamic>`. Datasource bertanggung jawab penuh atas parsing.

```dart
// lib/features/maps/datasource/maps_remote_datasource.dart
class MapsRemoteDatasource {
  final DioClient _client;
  MapsRemoteDatasource(this._client);

  Future<LatLng> getCoordinates(String address) async {
    final res = await _client.get(
      endpoint: '/geocode/json',
      queryParams: {'address': address, 'key': 'API_KEY'},
    );
    return LatLng.fromJson(res.data['results'][0]);
  }
}
```

Registrasi di locator:

```dart
locator.registerLazySingleton(
  () => MapsRemoteDatasource(locator(instanceName: 'mapsApi')),
);
```

---

## Alur error handling

`DioClient` memetakan semua `DioException` menjadi `ApiException` sebelum dilempar ke caller. Datasource tidak perlu catch `DioException` — cukup catch `ApiException`.

```
DioException  →  DioClient.errorMapper()  →  ApiException
NetworkException (no internet)            →  ApiException
```

Di repository, wrap hasil datasource ke `Result<T, AppError>`:

```dart
// lib/features/auth/repository/auth_repository_impl.dart
Future<AppResult<AuthData>> login(String email, String password) async {
  try {
    final data = await _remote.login(email, password);
    await _authNotifier.setSession(data);
    return Result.ok(data);
  } on ApiException catch (e) {
    return Result.err(e.error);
  } on ParsingException catch (e) {
    return Result.err(e.error);
  }
}
```

Jangan biarkan `ApiException` melewati batas repository — selalu wrap ke `Result.err(AppError(...))`.

---

## ResponseDto

Response dari backend utama mengikuti schema:

```json
{
  "status": 200,
  "error": false,
  "message": "Successfully",
  "data": {}
}
```

Field pagination (`total`, `per_page`, `current_page`, dll) tersedia untuk endpoint list. `data` bisa `null` untuk endpoint yang tidak mengembalikan payload (misalnya logout).

---

## Aturan

| Layer | Boleh | Tidak Boleh |
|---|---|---|
| Widget | — | Sentuh DioClient atau AppApiClient |
| Cubit/Bloc | — | Panggil datasource langsung |
| Repository | Tangkap `ApiException`, return `Result` | Lempar exception ke Cubit |
| Datasource | Panggil `AppApiClient` atau `DioClient` | Tangkap `DioException` sendiri |
| DioClient | Transport + error mapping | Tahu tentang `ResponseDto` atau auth |
| AppApiClient | Map `Response` → `ResponseDto` | Tahu tentang domain/fitur apapun |

---

## Yang tidak boleh dilakukan

- **Jangan buat `DioClient` baru di luar locator** — selalu gunakan instance dari GetIt.
- **Jangan inject `DioClient` langsung ke repository** — gunakan datasource sebagai perantara.
- **Jangan parse `ResponseDto` di repository** — parsing adalah tanggung jawab datasource.
- **Jangan tambahkan interceptor auth ke instance eksternal** — Bearer token tidak boleh dikirim ke API pihak ketiga.
- **Jangan catch `DioException` di datasource** — `DioClient` sudah memetakannya ke `ApiException`.
- **Jangan hardcode base URL di datasource** — base URL adalah konfigurasi locator, bukan urusan datasource.
