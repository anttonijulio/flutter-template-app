import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:template_app/core/services/firebase/firebase_messaging_service.dart';
import 'package:template_app/injection/locator.dart';
import 'package:template_app/core/services/notification/notification_dispatcher.dart';
import 'package:template_app/core/services/notification/notification_service.dart';
import 'package:template_app/router/app_router.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = locator<AppRouter>().router;
    // Check for notification taps that happened while app was in background
    // or terminated. Must run after the first frame so the router is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumePendingNotification());
  }

  Future<void> _consumePendingNotification() async {
    // Local notification: background tap (Android) or terminated tap
    final localPayload = await locator<NotificationService>().consumePendingPayload();
    if (localPayload != null) {
      locator<NotificationDispatcher>().dispatchPayload(localPayload);
      return;
    }

    // FCM: terminated tap or data-only background message
    await locator<FirebaseMessagingService>().consumePendingMessage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router);
  }
}
