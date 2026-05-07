import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:template_app/core/services/datasources/local_storage/storage_key.dart';

/// Top-level function — required by flutter_local_notifications.
///
/// Runs in a separate Dart isolate (Android background / terminated).
/// This isolate has its own clean memory heap: GetIt, LocalStorage, GoRouter,
/// and all Dart singletons from the main isolate do NOT exist here.
/// SharedPreferences.getInstance() is safe because it calls a platform channel
/// directly to OS storage — it does not depend on any Dart object being alive.
@pragma('vm:entry-point')
Future<void> onBackgroundNotificationResponse(
  NotificationResponse response,
) async {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(StorageKey.pendingLocalPayload, payload);
}