import 'package:template_app/core/services/notification/notification_payload.dart';
import 'package:template_app/core/utilities/logger.dart';

/// Implement this in each feature that needs to react to a notification tap.
abstract interface class NotificationHandler {
  /// Must match the [NotificationPayload.type] string this handler owns.
  String get type;
  void handle(NotificationPayload payload);
}

/// Central dispatcher — registered once in [initLocator], receives every
/// notification tap and routes it to the correct [NotificationHandler].
class NotificationDispatcher {
  static const _logLabel = 'NotificationDispatcher';

  final Map<String, NotificationHandler> _registry = {};

  /// Call once per handler, typically right after [initLocator] registers
  /// the feature's dependencies.
  void register(NotificationHandler handler) {
    assert(
      !_registry.containsKey(handler.type),
      'Duplicate handler for type "${handler.type}"',
    );
    _registry[handler.type] = handler;
    Log.d('Registered handler: ${handler.type}', label: _logLabel);
  }

  /// Parses [raw] and routes to the matching handler.
  /// Pass [NotificationResponse.payload] from [NotificationService] — keeps
  /// this class free of any plugin dependency.
  void dispatch(String? raw) {
    if (raw == null || raw.isEmpty) return;

    try {
      dispatchPayload(NotificationPayload.fromString(raw));
    } catch (e, st) {
      Log.e('Dispatch failed', label: _logLabel, error: e, stackTrace: st);
    }
  }

  /// Call this with payloads retrieved from [NotificationService.consumePendingPayload]
  /// to handle background and terminated-app cases.
  void dispatchPayload(NotificationPayload payload) {
    final handler = _registry[payload.type];
    if (handler == null) {
      Log.w('No handler for type: "${payload.type}"', label: _logLabel);
      return;
    }
    Log.d('Dispatching: ${payload.type}', label: _logLabel);
    handler.handle(payload);
  }
}