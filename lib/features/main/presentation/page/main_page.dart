import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _viewIndex = 0;

  void _updateView(int newIndex) async {
    if (!mounted) return;
    _viewIndex = newIndex;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const contentViews = [
      Center(child: Text("View1")),
      Center(child: Text("View2")),
      Center(child: Text("View3")),
      Center(child: Text("View4")),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text("MainPage")),
      body: contentViews[_viewIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: _updateView,
        items: List.generate(contentViews.length, (index) {
          return BottomNavigationBarItem(
            label: 'View${index + 1}',
            activeIcon: Icon(Icons.featured_play_list),
            icon: Icon(Icons.featured_play_list_outlined),
          );
        }),
      ),
    );
  }
}
