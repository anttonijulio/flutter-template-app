import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:template_app/core/services/firebase/firebase_background.dart';
import 'package:template_app/core/services/notification/notification_dispatcher.dart';
import 'package:template_app/core/services/notification/notification_payload.dart';
import 'package:template_app/core/services/notification/notification_service.dart';
import 'package:template_app/core/utilities/logger.dart';

class FirebaseMessagingService {
  static const _logLabel = 'FirebaseMessagingService';

  final NotificationService _notificationService;
  final NotificationDispatcher _dispatcher;

  FirebaseMessagingService(this._notificationService, this._dispatcher);

  Future<void> initialize() async {
    // Register background isolate handler (must be top-level function).
    FirebaseMessaging.onBackgroundMessage(onFirebaseBackgroundMessage);

    // iOS: let APNs show notification banner even when app is in foreground.
    // Android ignores this call.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    Log.i('Initialized', label: _logLabel);
  }

  /// Call from [App.initState] (after first frame) to handle:
  /// - Terminated app launched by tapping a FCM notification.
  /// - Data-only background message stored by [onFirebaseBackgroundMessage].
  Future<void> consumePendingMessage() async {
    // Case: app was terminated, user tapped FCM notification → cold start.
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) {
      Log.i('Launched from FCM: ${message.data}', label: _logLabel);
      _dispatchMessage(message);
      return;
    }

    // Case: data-only background message saved by the background isolate.
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kPendingFcmKey);
    if (raw != null && raw.isNotEmpty) {
      await prefs.remove(kPendingFcmKey);
      Log.i('Pending FCM data message: $raw', label: _logLabel);
      try {
        _dispatcher.dispatchPayload(NotificationPayload.fromString(raw));
      } catch (e, st) {
        Log.e(
          'Failed to parse pending FCM payload',
          label: _logLabel,
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  /// Returns the current FCM registration token.
  /// Send this to your backend so it can target this device.
  Future<String?> getToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    Log.d('Token: $token', label: _logLabel);
    return token;
  }

  /// Emits a new token whenever FCM rotates it.
  /// Listen and sync the new token to your backend.
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    Log.d('Subscribed: $topic', label: _logLabel);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    Log.d('Unsubscribed: $topic', label: _logLabel);
  }

  // ---------------------------------------------------------------------------

  void _onForegroundMessage(RemoteMessage message) {
    Log.i('Foreground FCM: ${message.data}', label: _logLabel);

    final notification = message.notification;
    if (notification != null) {
      // iOS: APNs already shows the banner via setForegroundNotificationPresentationOptions.
      // Android: must show manually — FCM never auto-displays in foreground.
      if (defaultTargetPlatform != TargetPlatform.iOS) {
        _notificationService.show(
          id: message.hashCode,
          title: notification.title ?? '',
          body: notification.body ?? '',
          payload: _buildPayload(message)?.encode(),
        );
      }
    } else {
      // Data-only: no UI needed, dispatch immediately on all platforms.
      final payload = _buildPayload(message);
      if (payload != null) _dispatcher.dispatchPayload(payload);
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    Log.i('FCM tap (background): ${message.data}', label: _logLabel);
    _dispatchMessage(message);
  }

  void _dispatchMessage(RemoteMessage message) {
    final payload = _buildPayload(message);
    if (payload != null) _dispatcher.dispatchPayload(payload);
  }

  NotificationPayload? _buildPayload(RemoteMessage message) {
    final type = message.data['type'] as String?;
    if (type == null) {
      Log.w('FCM message missing "type" field in data', label: _logLabel);
      return null;
    }
    return NotificationPayload(
      type: type,
      data: Map<String, dynamic>.from(message.data),
    );
  }
}
