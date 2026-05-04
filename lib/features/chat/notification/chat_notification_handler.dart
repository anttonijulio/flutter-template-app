import 'package:template_app/core/services/notification/notification_dispatcher.dart';
import 'package:template_app/core/services/notification/notification_payload.dart';
import 'package:template_app/core/utilities/logger.dart';
import 'package:template_app/router/app_router.dart';

class ChatNotificationHandler implements NotificationHandler {
  const ChatNotificationHandler(this._router);

  final AppRouter _router;

  @override
  String get type => NotificationType.chat;

  @override
  void handle(NotificationPayload payload) {
    final roomId = payload.data['room_id'] as String?;
    if (roomId == null) {
      Log.w('chat notification missing room_id', label: 'ChatNotificationHandler');
      return;
    }
    _router.router.go('/chat/$roomId');
  }
}