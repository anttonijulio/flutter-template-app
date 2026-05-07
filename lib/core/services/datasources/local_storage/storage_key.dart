class StorageKey {
  StorageKey._();

  // AUTH
  static const String hasLaunchedBefore = 'HAS_LAUNCHED_BEFORE';

  // NOTIFICATION — background tap handoff (consume once on app resume)
  static const String pendingLocalPayload = 'pending_notification_payload';
  static const String pendingAwesomePayload = 'pending_awesome_payload';
  static const String pendingFcmPayload = 'pending_fcm_payload';
}
