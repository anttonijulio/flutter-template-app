import 'package:flutter/material.dart';

class KeyboardDismisser extends StatelessWidget {
  final Widget child;
  final bool dismissOnTapOutside;
  final bool dismissOnDrag;

  final VoidCallback? onTapOutside;
  final VoidCallback? onDrag;

  const KeyboardDismisser({
    super.key,
    required this.child,
    this.dismissOnTapOutside = true,
    this.dismissOnDrag = false,
    this.onTapOutside,
    this.onDrag,
  });

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _handleTap(BuildContext context) {
    _dismissKeyboard();
    onTapOutside?.call();
  }

  void _handleDrag() {
    _dismissKeyboard();
    onDrag?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget current = child;

    if (dismissOnTapOutside) {
      current = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _handleTap(context),
        child: current,
      );
    }

    if (dismissOnDrag) {
      current = NotificationListener<UserScrollNotification>(
        onNotification: (_) {
          _handleDrag();
          return false;
        },
        child: current,
      );
    }

    return current;
  }
}
