import 'package:flutter/material.dart';

class AppDialogAction {
  const AppDialogAction({
    required this.label,
    this.onPressed,
    this.isDefault = false,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isDefault;
  final bool isDestructive;
}

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.primaryAction,
    this.secondaryAction,
    this.canPop = true,
    this.dismissible = true,
    this.adaptive = false,
  }) : assert(
         (primaryAction != null) || (secondaryAction == null),
         'secondaryAction tidak bisa diisi tanpa primaryAction.',
       );

  final String? title;
  final String? message;
  final Widget? icon;

  final AppDialogAction? primaryAction;
  final AppDialogAction? secondaryAction;

  final bool adaptive;
  final bool dismissible;
  final bool canPop;

  Future<T?> show<T>(BuildContext context) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      builder: (_) => this,
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];
    if (secondaryAction != null) {
      actions.add(_buildButton(context, secondaryAction!));
    }
    if (primaryAction != null) {
      actions.add(_buildButton(context, primaryAction!));
    }
    return actions;
  }

  Widget _buildButton(BuildContext context, AppDialogAction action) {
    final onPressed =
        action.onPressed ?? () => Navigator.of(context).maybePop();
    final scheme = Theme.of(context).colorScheme;
    final fg = action.isDestructive ? scheme.error : null;

    if (action.isDefault) {
      return FilledButton(
        onPressed: onPressed,
        style: action.isDestructive
            ? FilledButton.styleFrom(backgroundColor: scheme.error)
            : null,
        child: Text(action.label),
      );
    }
    return TextButton(
      onPressed: onPressed,
      style: fg != null ? TextButton.styleFrom(foregroundColor: fg) : null,
      child: Text(action.label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleWidget = title != null ? Text(title!) : null;
    final messageWidget = message != null ? Text(message!) : null;
    final actions = _buildActions(context);

    final dialog = adaptive
        ? AlertDialog.adaptive(
            icon: icon,
            title: titleWidget,
            content: messageWidget,
            actions: actions.isEmpty ? null : actions,
          )
        : AlertDialog(
            icon: icon,
            title: titleWidget,
            content: messageWidget,
            actions: actions.isEmpty ? null : actions,
          );

    return PopScope(canPop: canPop, child: dialog);
  }
}
