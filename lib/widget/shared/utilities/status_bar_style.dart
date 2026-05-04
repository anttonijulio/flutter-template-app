import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
export 'package:flutter/services.dart';

class StatusBarStyle extends StatelessWidget {
  final Widget child;
  final SystemUiOverlayStyle? style;

  const StatusBarStyle({super.key, this.style, required this.child});

  factory StatusBarStyle.light({required Widget child, Color? statusBarColor}) {
    return StatusBarStyle(
      style: SystemUiOverlayStyle(
        statusBarColor: statusBarColor ?? Colors.transparent,
        statusBarBrightness: .dark,
        statusBarIconBrightness: .light,
      ),
      child: child,
    );
  }

  factory StatusBarStyle.dark({required Widget child, Color? statusBarColor}) {
    return StatusBarStyle(
      style: SystemUiOverlayStyle(
        statusBarColor: statusBarColor ?? Colors.transparent,
        statusBarBrightness: .light,
        statusBarIconBrightness: .dark,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          style ??
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: .light,
            statusBarIconBrightness: .dark,
          ),
      child: child,
    );
  }
}
