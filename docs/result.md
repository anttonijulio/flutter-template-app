# Result<S, E> — Panduan Penggunaan

`Result<S, E>` adalah sealed class untuk merepresentasikan dua kemungkinan hasil operasi: **sukses** (`Success`) atau **gagal** (`Failure`). Semua operasi data di project ini wajib mengembalikan `Result` — jangan throw exception lintas layer.

---

## Tipe Alias

```dart
typedef AppResult<T> = Result<T, AppError>;
```

Gunakan `AppResult<T>` untuk semua operasi yang error-nya bertipe `AppError` (standar di project ini).

---

## Membuat Result

### Sukses

```dart
// Via factory
Result.success(data);

// Via static helper (AppResult)
Result.ok(data);
```

### Gagal

```dart
// Via factory
Result.failure(AppError(title: 'Error', message: 'Terjadi kesalahan', code: 500));

// Via static helper (AppResult)
Result.err(AppError(title: 'Error', message: 'Terjadi kesalahan', code: 500));
```

---

## Mengambil Value

### 1. `when()` — Wajib handle kedua case (direkomendasikan di UI/Cubit)

```dart
final result = await userRepository.fetchUser(id);

return result.when(
  success: (user) => UserState.loaded(user),
  failure: (error) => UserState.error(error.message),
);
```

### 2. Pattern matching `switch` — Idiomatis di Dart 3

```dart
switch (result) {
  case Success(:final data):
    print(data);
  case Failure(:final error):
    print(error.message);
}
```

### 3. `dataOrNull` — Untuk kasus null sudah aman diabaikan

```dart
final user = result.dataOrNull;
if (user != null) {
  // gunakan user
}
```

### 4. `errorOrNull` — Untuk mengambil error jika ada

```dart
final error = result.errorOrNull;
if (error != null) {
  showSnackbar(error.message);
}
```

### 5. `getOrElse()` — Dengan fallback value

```dart
final user = result.getOrElse(() => User.guest());
```

---

## Mengecek Status

```dart
if (result.isSuccess) { ... }
if (result.isFailure) { ... }
```

---

## Transformasi

### `map()` — Transform value sukses, biarkan error lewat

```dart
final AppResult<UserModel> result = await userRepository.fetchUser(id);

// Transform DTO → Model tanpa unwrap manual
final AppResult<String> nameResult = result.map((user) => user.name);
```

### `mapError()` — Transform error, biarkan value sukses lewat

```dart
final result = remoteResult.mapError(
  (error) => AppError(title: 'Gagal', message: error.message, code: error.code),
);
```

### `flatMap()` — Chain operasi yang juga mengembalikan Result

```dart
final AppResult<String> tokenResult = await authRepository.login(credentials);

final AppResult<User> userResult = await tokenResult.flatMap(
  (token) => userRepository.fetchProfile(token),
);
```

---

## Pola Penggunaan di Setiap Layer

### Data Layer (Repository / Datasource)

Tangkap exception dan wrap ke `Result.failure`:

```dart
Future<AppResult<User>> fetchUser(String id) async {
  try {
    final response = await _apiClient.get('/users/$id');
    return Result.ok(User.fromJson(response.data));
  } on ApiException catch (e) {
    return Result.err(AppError(title: 'Gagal', message: e.message, code: e.statusCode));
  } on NetworkException catch (e) {
    return Result.err(AppError(title: 'Tidak Ada Koneksi', message: e.message, code: 0));
  } on ParsingException catch (e) {
    return Result.err(AppError(title: 'Parsing Error', message: e.message, code: -1));
  }
}
```

### Domain Layer (UseCase)

Chain operasi dengan `flatMap` atau `map`:

```dart
Future<AppResult<ProfileViewModel>> call(String id) async {
  final userResult = await _userRepository.fetchUser(id);
  return userResult.map((user) => ProfileViewModel.fromUser(user));
}
```

### State Layer (Cubit/Bloc)

Gunakan `when()` untuk emit state:

```dart
Future<void> loadUser(String id) async {
  emit(state.copyWith(requestState: RequestState.loading));

  final result = await _fetchUserUseCase(id);

  result.when(
    success: (user) => emit(state.copyWith(
      requestState: RequestState.success,
      user: user,
    )),
    failure: (error) => emit(state.copyWith(
      requestState: RequestState.error,
      errorMessage: error.message,
    )),
  );
}
```

---

## Referensi API

| Member | Tipe | Keterangan |
|---|---|---|
| `Result.success(data)` | Factory | Buat instance `Success` |
| `Result.failure(error)` | Factory | Buat instance `Failure` |
| `Result.ok(data)` | Static | Shorthand `AppResult` sukses |
| `Result.err(error)` | Static | Shorthand `AppResult` gagal |
| `when(success:, failure:)` | Method | Handle kedua case, wajib exhaustive |
| `isSuccess` | Getter | `true` jika `Success` |
| `isFailure` | Getter | `true` jika `Failure` |
| `dataOrNull` | Getter | Value sukses atau `null` |
| `errorOrNull` | Getter | Error atau `null` |
| `map(transform)` | Extension | Transform value, propagate error |
| `mapError(transform)` | Extension | Transform error, propagate value |
| `flatMap(transform)` | Extension | Chain operasi yang mengembalikan `Result` |
| `getOrElse(fallback)` | Extension | Value sukses atau hasil fallback |
