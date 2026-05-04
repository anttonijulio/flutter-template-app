import 'package:flutter/material.dart';

enum AppButtonType { filled, elevated, outlined, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.onPressed,
    this.label,
    this.child,
    this.foregroundColor,
    this.backgroundColor,
    this.style,
    this.type = .filled,
  });

  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle =
        style ??
        ButtonStyle(
          foregroundColor: foregroundColor != null
              ? WidgetStatePropertyAll(foregroundColor)
              : null,
          backgroundColor: backgroundColor != null
              ? WidgetStatePropertyAll(backgroundColor)
              : null,
        );

    final resolvedOnPressed = onPressed ?? () {};

    return switch (type) {
      .filled => FilledButton(
        onPressed: resolvedOnPressed,
        style: resolvedStyle,
        child: _buildChild(),
      ),
      .elevated => ElevatedButton(
        onPressed: resolvedOnPressed,
        style: resolvedStyle,
        child: _buildChild(),
      ),
      .outlined => OutlinedButton(
        onPressed: resolvedOnPressed,
        style: resolvedStyle,
        child: _buildChild(),
      ),
      .text => TextButton(
        onPressed: resolvedOnPressed,
        style: resolvedStyle,
        child: _buildChild(),
      ),
    };
  }

  Widget _buildChild() {
    if (label != null) return Text(label!);
    return child ?? const SizedBox.shrink();
  }
}
