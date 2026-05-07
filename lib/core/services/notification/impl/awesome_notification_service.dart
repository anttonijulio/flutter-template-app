import 'package:awesome_notifications/awesome_notifications.dart' as awn;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:template_app/core/services/datasources/local_storage/storage_key.dart';
import 'package:template_app/core/services/notification/notification_channel.dart';
import 'package:template_app/core/services/notification/notification_payload.dart';
import 'package:template_app/core/services/notification/notification_service.dart';
import 'package:template_app/core/utilities/logger.dart';

const _payloadDataKey = 'data';

class AwesomeNotificationService implements NotificationService {
  static const _logLabel = 'AwesomeNotificationService';

  /// awesome_notifications listeners must be static. We bridge to the live
  /// instance via this static field — set in [initialize].
  static void Function(String? payload)? _liveOnTap;

  @override
  Future<void> initialize({void Function(String? payload)? onTap}) async {
    _liveOnTap = onTap;

    await awn.AwesomeNotifications().initialize(
      'resource://drawable/ic_stat_notification',
      [
        for (final ch in NotificationChannel.values)
          awn.NotificationChannel(
            channelKey: ch.id,
            channelName: ch.name,
            channelDescription: ch.description,
            importance: ch.importance.toPlugin(),
          ),
      ],
      debug: false,
    );

    await awn.AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
    );

    Log.i('Initialized', label: _logLabel);
  }

  @override
  Future<bool> requestPermission() async {
    final allowed = await awn.AwesomeNotifications().isNotificationAllowed();
    if (allowed) return true;
    return await awn.AwesomeNotifications()
        .requestPermissionToSendNotifications();
  }

  @override
  Future<NotificationPayload?> consumePendingPayload() async {
    // Case: cold start from a notification tap
    final initialAction = await awn.AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: true);
    final initialRaw = initialAction?.payload?[_payloadDataKey];
    if (initialRaw != null && initialRaw.isNotEmpty) {
      Log.i('Launch from notification: $initialRaw', label: _logLabel);
      try {
        return NotificationPayload.fromString(initialRaw);
      } catch (e, st) {
        Log.e(
          'Failed to parse launch payload',
          label: _logLabel,
          error: e,
          stackTrace: st,
        );
      }
    }

    // Case: tap arrived in background isolate while app was terminated
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKey.pendingAwesomePayload);
    if (raw != null && raw.isNotEmpty) {
      await prefs.remove(StorageKey.pendingAwesomePayload);
      Log.i('Pending background notification: $raw', label: _logLabel);
      try {
        return NotificationPayload.fromString(raw);
      } catch (e, st) {
        Log.e(
          'Failed to parse pending payload',
          label: _logLabel,
          error: e,
          stackTrace: st,
        );
      }
    }

    return null;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    NotificationChannel channel = NotificationChannel.general,
    String? payload,
  }) async {
    await awn.AwesomeNotifications().createNotification(
      content: awn.NotificationContent(
        id: id,
        channelKey: channel.id,
        title: title,
        body: body,
        payload: payload != null ? {_payloadDataKey: payload} : null,
        notificationLayout: awn.NotificationLayout.Default,
      ),
    );
    Log.d('Shown: id=$id title=$title', label: _logLabel);
  }

  @override
  Future<void> cancel(int id) async {
    await awn.AwesomeNotifications().cancel(id);
    Log.d('Cancelled: id=$id', label: _logLabel);
  }

  @override
  Future<void> cancelAll() async {
    await awn.AwesomeNotifications().cancelAll();
    Log.d('All cancelled', label: _logLabel);
  }

  /// Top-level / static — required by awesome_notifications.
  /// Runs in the main isolate when the app is alive, in a background isolate
  /// when the app is terminated.
  @pragma('vm:entry-point')
  static Future<void> _onActionReceivedMethod(awn.ReceivedAction action) async {
    final raw = action.payload?[_payloadDataKey];
    if (raw == null || raw.isEmpty) return;

    if (_liveOnTap != null) {
      Log.i('Tapped (foreground): $raw', label: _logLabel);
      _liveOnTap!.call(raw);
    } else {
      // Background isolate or pre-initialize — persist for consumePendingPayload
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKey.pendingAwesomePayload, raw);
    }
  }
}

extension on NotificationImportance {
  awn.NotificationImportance toPlugin() => switch (this) {
    NotificationImportance.min => awn.NotificationImportance.Min,
    NotificationImportance.low => awn.NotificationImportance.Low,
    NotificationImportance.defaultLevel => awn.NotificationImportance.Default,
    NotificationImportance.high => awn.NotificationImportance.High,
    NotificationImportance.max => awn.NotificationImportance.Max,
  };
}
