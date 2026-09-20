import 'package:flutter/material.dart';

const callbackNotificationKey = ValueKey('callback-notification');

void showCallbackNotification(
  BuildContext context,
  String callback, [
  Object? value,
]) {
  final message = value == null
      ? '$callback called'
      : '$callback called with $value';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, key: callbackNotificationKey),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
