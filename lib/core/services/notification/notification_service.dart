import 'package:template_app/core/services/notification/notification_channel.dart';
import 'package:template_app/core/services/notification/notification_payload.dart';

/// Plugin-agnostic contract for showing local notifications and handling taps.
///
/// Implementations live next to this file (e.g. [FlutterLocalNotificationService],
/// [AwesomeNotificationService]). Swap implementations in [initLocator] without
/// touching feature code.
abstract interface class NotificationService {
  /// Initialize the underlying plugin and register channels.
  /// [onTap] receives the raw payload string from a foreground tap.
  Future<void> initialize({void Function(String? payload)? onTap});

  /// Request OS notification permission. Returns whether it was granted.
  Future<bool> requestPermission();

  /// Returns the payload from a tap that arrived while the app was
  /// terminated/background, or null if the app was launched normally.
  /// Call once on app start, after [initialize].
  Future<NotificationPayload?> consumePendingPayload();

  /// Display a notification immediately.
  Future<void> show({
    required int id,
    required String title,
    required String body,
    NotificationChannel channel = NotificationChannel.general,
    String? payload,
  });

  /// Cancel a single posted notification by id.
  Future<void> cancel(int id);

  /// Cancel all posted notifications.
  Future<void> cancelAll();
}
