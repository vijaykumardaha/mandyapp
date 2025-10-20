import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:flutter/material.dart';

class Info {
  static message(String message,
      {GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
      BuildContext? context,
      Duration? duration,
      SnackBarBehavior snackBarBehavior = SnackBarBehavior.floating}) {
    duration ??= Duration(seconds: 3);
    ThemeData theme = AppTheme.theme;

    SnackBar snackBar = SnackBar(
      duration: duration,
      content: MyText(
        message,
        color: theme.colorScheme.onPrimary,
      ),
      backgroundColor: theme.colorScheme.primary,
      behavior: snackBarBehavior,
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
    );

    if (scaffoldMessengerKey != null) {
      scaffoldMessengerKey.currentState!.showSnackBar(snackBar);
    } else if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {}
  }

  static error(String message,
      {GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
      BuildContext? context,
      Duration? duration,
      SnackBarBehavior snackBarBehavior = SnackBarBehavior.floating}) {
    duration ??= Duration(seconds: 3);
    ThemeData theme = AppTheme.theme;

    SnackBar snackBar = SnackBar(
      duration: duration,
      content: MyText(
        message,
        color: theme.colorScheme.onError,
      ),
      backgroundColor: theme.colorScheme.error,
      behavior: snackBarBehavior,
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
    );

    if (scaffoldMessengerKey != null) {
      scaffoldMessengerKey.currentState!.showSnackBar(snackBar);
    } else if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {}
  }
}
