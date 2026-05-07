import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:template_app/core/services/datasources/local_storage/storage_key.dart';
import 'package:template_app/core/services/notification/notification_payload.dart';

/// Top-level function — required by firebase_messaging for background handling.
///
/// Runs in a separate Dart isolate. GetIt, LocalStorage, GoRouter, and all
/// Dart singletons from the main isolate do NOT exist here.
///
/// FCM messages that carry a [RemoteNotification] are automatically displayed
/// by the FCM SDK — no action needed. Only data-only messages need manual
/// handling: we persist the payload to SharedPreferences and dispatch it
/// the next time the app is in the foreground.
@pragma('vm:entry-point')
Future<void> onFirebaseBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();

  // FCM SDK already shows the notification — only care about data-only messages.
  if (message.notification != null) return;

  final type = message.data['type'] as String?;
  if (type == null) return;

  final payload = NotificationPayload(
    type: type,
    data: Map<String, dynamic>.from(message.data),
  );

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(StorageKey.pendingFcmPayload, payload.encode());
}
