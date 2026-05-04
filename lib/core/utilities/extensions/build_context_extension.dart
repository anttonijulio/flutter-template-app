import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get paddingBottom => mediaQuery.padding.bottom;
  double get paddingTop => mediaQuery.padding.top;
  double get screenHeight => mediaQuery.size.height;
  double get screenWidth => mediaQuery.size.width;
  double heightPercent(double percent, {bool includeSafeArea = true}) {
    final p = percent.clamp(0.0, 1.0);
    final height = includeSafeArea
        ? screenHeight
        : screenHeight - paddingTop - paddingBottom;
    return height * p;
  }
}
