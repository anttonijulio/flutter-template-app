import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:template_app/core/services/notification/notification_background.dart';
import 'package:template_app/core/services/notification/notification_channel.dart';
import 'package:template_app/core/services/notification/notification_payload.dart';
import 'package:template_app/core/utilities/logger.dart';

class NotificationService {
  static const _logLabel = 'NotificationService';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  void Function(String? payload)? onNotificationTap;

  Future<void> initialize({void Function(String? payload)? onTap}) async {
    onNotificationTap = onTap;

    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_stat_notification',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: settings,
      // Case 1: foreground tap + background-but-not-terminated tap (iOS)
      onDidReceiveNotificationResponse: (response) {
        Log.i('Tapped (foreground): ${response.payload}', label: _logLabel);
        onNotificationTap?.call(response.payload);
      },
      // Case 2: Android background/terminated tap → separate isolate, saves to SharedPreferences
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );

    await _createAndroidChannels();
    Log.i('Initialized', label: _logLabel);
  }

  /// Call once on app start (in [App.initState]) to handle taps that arrived
  /// while the app was in the background or terminated.
  ///
  /// Returns the pending [NotificationPayload] and clears the stored state,
  /// or null if the app was launched normally.
  Future<NotificationPayload?> consumePendingPayload() async {
    // Case 3: app was terminated, user tapped notification → app cold-started
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final raw = launchDetails!.notificationResponse?.payload;
      if (raw != null && raw.isNotEmpty) {
        Log.i('Launch from notification: $raw', label: _logLabel);
        try {
          return NotificationPayload.fromString(raw);
        } catch (e, st) {
          Log.e(
            'Failed to parse launch payload',
            label: _logLabel,
            error: e,
            stackTrace: st,
          );
        }
      }
    }

    // Case 2: Android background handler stored the payload to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kPendingNotificationKey);
    if (raw != null && raw.isNotEmpty) {
      await prefs.remove(kPendingNotificationKey); // consume once
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

  Future<void> _createAndroidChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    for (final ch in NotificationChannel.values) {
      await android.createNotificationChannel(
        AndroidNotificationChannel(
          ch.id,
          ch.name,
          description: ch.description,
          importance: ch.importance.toPlugin(),
        ),
      );
    }
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    NotificationChannel channel = NotificationChannel.general,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance.toPlugin(),
        priority: channel.priority.toPlugin(),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
    Log.d('Shown: id=$id title=$title', label: _logLabel);
  }

  Future<void> showBigText({
    required int id,
    required String title,
    required String body,
    required String bigText,
    NotificationChannel channel = NotificationChannel.general,
    String? summaryText,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance.toPlugin(),
        priority: channel.priority.toPlugin(),
        styleInformation: BigTextStyleInformation(
          bigText,
          contentTitle: title,
          summaryText: summaryText,
        ),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
    Log.d('BigText shown: id=$id', label: _logLabel);
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
    Log.d('Cancelled: id=$id', label: _logLabel);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    Log.d('All cancelled', label: _logLabel);
  }

  Future<List<ActiveNotification>> getActive() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.getActiveNotifications() ?? [];
  }
}

extension on NotificationImportance {
  Importance toPlugin() => switch (this) {
    NotificationImportance.min => Importance.min,
    NotificationImportance.low => Importance.low,
    NotificationImportance.defaultLevel => Importance.defaultImportance,
    NotificationImportance.high => Importance.high,
    NotificationImportance.max => Importance.max,
  };
}

extension on NotificationPriority {
  Priority toPlugin() => switch (this) {
    NotificationPriority.min => Priority.min,
    NotificationPriority.low => Priority.low,
    NotificationPriority.defaultLevel => Priority.defaultPriority,
    NotificationPriority.high => Priority.high,
    NotificationPriority.max => Priority.max,
  };
}
