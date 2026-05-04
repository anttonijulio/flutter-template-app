import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:template_app/router/app_routes.dart';
import 'package:template_app/features/auth/notifier/auth_notifier.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  final AuthNotifier _authNotifier;

  AppRouter(this._authNotifier);

  late final GoRouter router = GoRouter(
    routes: $appRoutes,
    navigatorKey: navigatorKey,
    refreshListenable: _authNotifier,
    debugLogDiagnostics: kDebugMode || kProfileMode,
    redirect: (context, state) {
      final isAuthenticated = _authNotifier.isAuthenticated;
      final currentPath = state.matchedLocation;

      // public routes (yang bisa diakses tanpa login)
      const publicRoutes = ['/welcome', '/login', '/register'];
      final isPublicRoute = publicRoutes.contains(currentPath);

      // Case 1: Belum login & akses protected route → redirect ke welcome
      if (!isAuthenticated && !isPublicRoute) {
        return '/welcome';
      }

      // Case 2: Sudah login & masih di public route → redirect ke main
      if (isAuthenticated && isPublicRoute) {
        return '/';
      }

      // No redirect needed
      return null;
    },
  );
}
