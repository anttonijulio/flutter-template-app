import 'dart:convert';

/// Notification type constants — add new types here as features grow.
abstract final class NotificationType {
  static const chat = 'chat';
  static const order = 'order';
  static const promo = 'promo';
}

class NotificationPayload {
  const NotificationPayload({
    required this.type,
    this.data = const {},
  });

  final String type;
  final Map<String, dynamic> data;

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      type: json['type'] as String,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
    );
  }

  factory NotificationPayload.fromString(String raw) {
    return NotificationPayload.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() => {'type': type, 'data': data};

  String encode() => jsonEncode(toJson());
}
