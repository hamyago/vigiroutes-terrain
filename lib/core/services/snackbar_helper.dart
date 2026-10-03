import 'package:flutter/material.dart';

/// Affiche un SnackBar en supprimant TOUJOURS le précédent.
///
/// Fix : évite que les messages se cumulent / persistent entre les navigations.
/// Utiliser systématiquement cette fonction à la place de
/// `ScaffoldMessenger.of(context).showSnackBar(...)`.
void showAppSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 3),
  SnackBarAction? action,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      action: action,
    ),
  );
}
