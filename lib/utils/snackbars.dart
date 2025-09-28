// lib/utils/snackbars.dart
import 'package:flutter/material.dart';

typedef UndoCallback = void Function();

class AppSnack {
  static void showUndo({
    required BuildContext context,
    required String message,
    required UndoCallback onUndo,
    Duration duration = const Duration(seconds: 5),
    IconData icon = Icons.undo,
  }) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: duration,
          content: Row(
            children: [
              Icon(icon, size: 18, color: cs.onInverseSurface),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          action: SnackBarAction(label: 'Undo', onPressed: onUndo),
        ),
      );
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    IconData icon = Icons.info_outline,
  }) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: duration,
          content: Row(
            children: [
              Icon(icon, size: 18, color: cs.onInverseSurface),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}
