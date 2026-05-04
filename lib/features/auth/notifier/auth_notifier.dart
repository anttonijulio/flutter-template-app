import 'package:flutter/foundation.dart';
import 'package:template_app/core/services/firebase/crashlytics_service.dart';
import 'package:template_app/features/auth/datasource/auth_secure_storage.dart';
import 'package:template_app/features/auth/repository/model/auth_data.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._secureStorage, this._crashlytics);

  final AuthSecureStorage _secureStorage;
  final CrashlyticsService _crashlytics;

  AuthData? _authData;

  AuthData? get authData => _authData;

  bool get isAuthenticated {
    final token = _authData?.accessToken;
    return token != null && token.isNotEmpty;
  }

  String? get token => _authData?.accessToken;

  // Dipanggil sekali saat initLocator() — memuat auth data ke memori
  // sebelum router pertama kali membaca isAuthenticated.
  Future<void> init() async {
    _authData = await _secureStorage.getAuthData();
    if (_authData != null) await _crashlytics.setUser(_authData!.uid);
  }

  Future<void> setSession(AuthData data) async {
    await _secureStorage.saveAuthData(data);
    _authData = data;
    await _crashlytics.setUser(data.uid);
    notifyListeners();
  }

  Future<void> clearSession() async {
    await _secureStorage.clearAuthData();
    _authData = null;
    await _crashlytics.clearUser();
    notifyListeners();
  }
}
