import 'package:flutter/material.dart';
import 'package:template_app/core/utilities/extensions/build_context_extension.dart';

class AppModalBottomSheet extends StatelessWidget {
  const AppModalBottomSheet({
    super.key,
    required this.content,
    this.borderRadius,
    this.constraints,
    this.backgroundColor,
    this.dismissible = true,
    this.enableDrag = true,
    this.showDragHandle = false,
    this.isScrollControlled = false,
  });

  final Widget content;

  final bool dismissible;
  final bool showDragHandle;
  final bool isScrollControlled;
  final BoxConstraints? constraints;
  final bool enableDrag;
  final Radius? borderRadius;
  final Color? backgroundColor;

  Future<T?> show<T>(BuildContext context) {
    final top = borderRadius ?? const Radius.circular(12);
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: dismissible,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      constraints: constraints,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: top),
      ),
      builder: (_) => this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.only(bottom: context.paddingBottom),
        child: content,
      ),
    );
  }
}
