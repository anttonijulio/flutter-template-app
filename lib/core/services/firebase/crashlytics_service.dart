import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:template_app/core/utilities/logger.dart';

class CrashlyticsService {
  static const _logLabel = 'CrashlyticsService';

  final FirebaseCrashlytics _crashlytics;

  CrashlyticsService() : _crashlytics = FirebaseCrashlytics.instance;

  /// Set after login — setiap crash akan tercatat dengan user ID ini.
  Future<void> setUser(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
    Log.d('User set: $userId', label: _logLabel);
  }

  /// Clear saat logout — crash setelah ini tidak tertautkan ke user manapun.
  Future<void> clearUser() async {
    await _crashlytics.setUserIdentifier('');
    Log.d('User cleared', label: _logLabel);
  }

  /// Catat custom key untuk konteks debugging (muncul di Crashlytics dashboard).
  /// Value bisa berupa String, bool, int, double.
  Future<void> setKey(String key, Object value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  /// Tambah breadcrumb log yang muncul di "Logs" tab pada laporan crash.
  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  /// Catat error secara manual — gunakan di catch block pada operasi kritis.
  /// Set [fatal] ke true hanya jika error menyebabkan app tidak bisa dilanjutkan.
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? reason,
  }) async {
    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
    Log.e(
      'Recorded${fatal ? ' fatal' : ''} error',
      label: _logLabel,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
