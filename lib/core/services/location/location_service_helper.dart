import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:template_app/core/utilities/logger.dart';

class LocationServiceHelper {
  LocationServiceHelper();

  static const MethodChannel _channel = MethodChannel(
    'template_app/location_service',
  );

  static const String _logLabel = 'LocationServiceHelper';

  /// Prompts the user to enable GPS.
  ///
  /// On Android, shows the Google Play Services in-app dialog (no redirect to
  /// system Settings). Returns `true` when location services end up enabled.
  ///
  /// On iOS there is no equivalent API — returns the current
  /// `CLLocationManager.locationServicesEnabled()` value with no dialog.
  Future<bool> requestService() async {
    try {
      final enabled = await _channel.invokeMethod<bool>('requestService');
      return enabled ?? false;
    } on PlatformException catch (e, s) {
      Log.e(
        'requestService failed: ${e.code} ${e.message}',
        label: _logLabel,
        error: e,
        stackTrace: s,
      );
      return false;
    } on MissingPluginException {
      Log.w(
        'requestService not implemented on ${Platform.operatingSystem}',
        label: _logLabel,
      );
      return false;
    }
  }
}