import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:template_app/core/utilities/logger.dart';

/// Keys for all Remote Config parameters.
/// Add new keys here and set matching defaults in [RemoteConfigService._defaults].
abstract final class RemoteConfigKey {
  // Example — remove or replace with real keys:
  // static const String forceUpdateVersion = 'force_update_version';
  // static const String maintenanceMode = 'maintenance_mode';
}

class RemoteConfigService {
  static const _logLabel = 'RemoteConfigService';

  /// Minimum interval between fetches in release mode.
  static const _fetchInterval = Duration(hours: 1);

  final FirebaseRemoteConfig _rc;

  RemoteConfigService() : _rc = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    await _rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // Use 0 in debug so every fetchAndActivate actually hits the server.
        minimumFetchInterval: const bool.fromEnvironment('dart.vm.product')
            ? _fetchInterval
            : Duration.zero,
      ),
    );

    await _rc.setDefaults(_defaults);

    try {
      await _rc.fetchAndActivate();
      Log.i('Fetched and activated', label: _logLabel);
    } catch (e, st) {
      // Non-fatal: stale / default values will be used.
      Log.e(
        'fetchAndActivate failed — using cached/defaults',
        label: _logLabel,
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Pull fresh values from the server and apply them immediately.
  /// Returns true if new values were activated.
  Future<bool> fetchAndActivate() async {
    try {
      final updated = await _rc.fetchAndActivate();
      Log.d('fetchAndActivate → updated=$updated', label: _logLabel);
      return updated;
    } catch (e, st) {
      Log.e(
        'fetchAndActivate failed',
        label: _logLabel,
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  String getString(String key) => _rc.getString(key);
  bool getBool(String key) => _rc.getBool(key);
  int getInt(String key) => _rc.getInt(key);
  double getDouble(String key) => _rc.getDouble(key);

  /// Raw [RemoteConfigValue] — useful when you need the value source metadata.
  RemoteConfigValue getValue(String key) => _rc.getValue(key);

  // ---------------------------------------------------------------------------
  // Default values — must mirror what is set in the Firebase console.
  // ---------------------------------------------------------------------------

  static const Map<String, dynamic> _defaults = {
    // RemoteConfigKey.forceUpdateVersion: '0.0.0',
    // RemoteConfigKey.maintenanceMode: false,
  };
}