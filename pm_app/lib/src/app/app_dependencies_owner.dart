import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_dependencies.dart';

typedef AppDependencyCloseErrorHandler =
    void Function(Object error, StackTrace stackTrace);

final class AppDependenciesOwner extends StatefulWidget {
  const AppDependenciesOwner({
    required this.dependencies,
    required this.child,
    this.onCloseError = _reportCloseError,
    super.key,
  });

  final AppDependencies dependencies;
  final Widget child;
  final AppDependencyCloseErrorHandler onCloseError;

  @override
  State<AppDependenciesOwner> createState() => _AppDependenciesOwnerState();

  static void _reportCloseError(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'pm_app',
        context: ErrorDescription('while closing application dependencies'),
      ),
    );
  }
}

final class _AppDependenciesOwnerState extends State<AppDependenciesOwner> {
  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    unawaited(_closeDependencies());
    super.dispose();
  }

  Future<void> _closeDependencies() async {
    try {
      await widget.dependencies.close();
    } catch (error, stackTrace) {
      widget.onCloseError(error, stackTrace);
    }
  }
}
