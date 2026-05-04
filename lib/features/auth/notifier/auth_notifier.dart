import 'package:flutter/foundation.dart';
import 'package:template_app/core/services/datasource/local_storage/local_storage.dart';
import 'package:template_app/core/services/datasource/local_storage/storage_key.dart';
import 'package:template_app/features/auth/repository/model/auth_data.dart';

class AuthNotifier extends ChangeNotifier {
  final LocalStorage _storage;

  AuthNotifier(this._storage);

  AuthData? get authData {
    final raw = _storage.getObject(StorageKey.authData);
    if (raw == null) return null;
    return AuthData.fromJson(raw);
  }

  bool get isAuthenticated {
    final token = authData?.accessToken;
    return token != null && token.isNotEmpty;
  }

  // Digunakan AuthInterceptor untuk inject Bearer token
  String? get token => authData?.accessToken;

  Future<void> setSession(AuthData data) async {
    await _storage.setObject(StorageKey.authData, data.toJson());
    notifyListeners();
  }

  Future<void> clearSession() async {
    await _storage.remove(StorageKey.authData);
    notifyListeners();
  }
}