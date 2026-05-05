import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:template_app/core/services/datasources/local_storage/local_storage.dart';
import 'package:template_app/core/services/datasources/local_storage/storage_key.dart';
import 'package:template_app/features/auth/repository/model/auth_data.dart';

class AuthSecureStorage {
  AuthSecureStorage(
    LocalStorage localStorage, {
    FlutterSecureStorage? secureStorage,
  }) : _localStorage = localStorage,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;
  final LocalStorage _localStorage;

  static const _keyAuthData = 'secure_auth_data';

  // Dipanggil saat init: hapus Keychain jika fresh install (iOS persistence fix).
  // SharedPreferences terhapus saat uninstall; Keychain tidak — flag ini menjadi
  // indikator reliable untuk membedakan fresh install vs session lama.
  Future<void> clearIfFreshInstall() async {
    final hasLaunched =
        _localStorage.getBool(StorageKey.hasLaunchedBefore) ?? false;
    if (!hasLaunched) {
      await _secureStorage.deleteAll();
      await _localStorage.setBool(StorageKey.hasLaunchedBefore, value: true);
    }
  }

  Future<AuthData?> getAuthData() async {
    final raw = await _secureStorage.read(key: _keyAuthData);
    if (raw == null) return null;
    try {
      return AuthData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAuthData(AuthData data) async {
    await _secureStorage.write(
      key: _keyAuthData,
      value: jsonEncode(data.toJson()),
    );
  }

  Future<void> clearAuthData() async {
    await _secureStorage.delete(key: _keyAuthData);
  }
}
