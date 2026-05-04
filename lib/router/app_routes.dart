import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:template_app/features/main/presentation/page/main_page.dart';

part 'app_routes.g.dart';

@TypedGoRoute<MainRoute>(path: '/')
class MainRoute extends GoRouteData with $MainRoute {
  const MainRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const MainPage();
}
