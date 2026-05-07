import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:template_app/core/services/datasources/local_storage/storage_key.dart';
import 'package:template_app/core/services/notification/impl/flutter_local_notification_background.dart';
import 'package:template_app/core/services/notification/notification_channel.dart';
import 'package:template_app/core/services/notification/notification_payload.dart';
import 'package:template_app/core/services/notification/notification_service.dart';
import 'package:template_app/core/utilities/logger.dart';

class FlutterLocalNotificationService implements NotificationService {
  static const _logLabel = 'FlutterLocalNotificationService';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  void Function(String? payload)? _onNotificationTap;

  @override
  Future<void> initialize({void Function(String? payload)? onTap}) async {
    _onNotificationTap = onTap;

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
        _onNotificationTap?.call(response.payload);
      },
      // Case 2: Android background/terminated tap → separate isolate, saves to SharedPreferences
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );

    await _createAndroidChannels();
    Log.i('Initialized', label: _logLabel);
  }

  @override
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
    final raw = prefs.getString(StorageKey.pendingLocalPayload);
    if (raw != null && raw.isNotEmpty) {
      await prefs.remove(StorageKey.pendingLocalPayload); // consume once
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

  @override
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

  @override
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

  @override
  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
    Log.d('Cancelled: id=$id', label: _logLabel);
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    Log.d('All cancelled', label: _logLabel);
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
