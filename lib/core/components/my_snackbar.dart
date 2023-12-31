import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

void showMySnackbarWithAwesome(
  BuildContext context, {
  required String title,
  required String message,
  required ContentType contentType,
  Duration? duration,
}) {
  final snackBar = SnackBar(
    /// need to set following properties for best effect of awesome_snackbar_content
    elevation: 0,
    padding: const EdgeInsets.all(18.0),
    duration: duration ?? const Duration(seconds: 2),
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    content: AwesomeSnackbarContent(
      title: title,
      message: message,
      /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
      contentType: contentType,
    ),
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}

// default snackbar
void showMySnackbar(
  BuildContext context, {
  required String message,
  Duration? duration,
  Color? backgroundColor,
  SnackBarAction? action,
}) {
  final snackBar = SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 1),
    backgroundColor: backgroundColor,
    action: action,
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}
