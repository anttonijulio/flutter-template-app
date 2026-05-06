import 'package:flutter/material.dart';
import 'package:template_app/features/main/presentation/page/main_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MainPage());
  }
}
