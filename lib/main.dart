import 'package:flutter/material.dart';
import 'package:template_app/injection/locator.dart';

import 'features/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //// dependencies injection
  await initLocator();

  runApp(const App());
}
