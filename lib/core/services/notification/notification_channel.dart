enum NotificationImportance { min, low, defaultLevel, high, max }

enum NotificationPriority { min, low, defaultLevel, high, max }

enum NotificationChannel {
  general(
    id: 'general_channel',
    name: 'General',
    description: 'General app notifications',
    importance: NotificationImportance.defaultLevel,
    priority: NotificationPriority.defaultLevel,
  ),
  promo(
    id: 'promo_channel',
    name: 'Promotions',
    description: 'Deals, offers, and promotional notifications',
    importance: NotificationImportance.low,
    priority: NotificationPriority.low,
  ),
  alert(
    id: 'alert_channel',
    name: 'Alerts',
    description: 'Important alerts that require immediate attention',
    importance: NotificationImportance.high,
    priority: NotificationPriority.high,
  );

  const NotificationChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.importance,
    required this.priority,
  });

  final String id;
  final String name;
  final String description;
  final NotificationImportance importance;
  final NotificationPriority priority;
}
