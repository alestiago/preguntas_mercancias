import 'dart:async';

import 'package:pm_persistence/pm_persistence.dart';

final class AppDependencies {
  AppDependencies({
    required this.questionProgressStore,
    required this.settingsStore,
  });

  final QuestionProgressStore questionProgressStore;
  final SettingsStore settingsStore;

  Future<void>? _closeFuture;

  Future<void> close() {
    return _closeFuture ??= Future.wait<void>([
      Future<void>.sync(questionProgressStore.close),
      Future<void>.sync(settingsStore.close),
    ]);
  }
}
