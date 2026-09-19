import 'package:flutter/material.dart';

/// Centralizes construction of the app's imperative page routes while keeping
/// Flutter's [Navigator] as the navigation mechanism.
abstract final class AppNavigator {
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(_route(page));
  }

  static Future<T?> replace<T, TO>(BuildContext context, Widget page) {
    return Navigator.of(context).pushReplacement<T, TO>(_route(page));
  }

  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }

  static MaterialPageRoute<T> _route<T>(Widget page) {
    return MaterialPageRoute<T>(builder: (_) => page);
  }
}
