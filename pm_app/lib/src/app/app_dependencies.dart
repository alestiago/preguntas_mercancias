import 'dart:async';

import 'package:pm_persistence/pm_persistence.dart';

import '../questions/load_questions.dart';

final class AppDependencies {
  AppDependencies({
    required this.questionProgressStore,
    required this.settingsStore,
    LoadQuestionCatalog? loadQuestionCatalog,
  }) : loadQuestionCatalog = cacheQuestionCatalog(
         loadQuestionCatalog ?? loadQuestionCatalogFromBank,
       );

  final QuestionProgressStore questionProgressStore;
  final SettingsStore settingsStore;
  final LoadQuestionCatalog loadQuestionCatalog;

  Future<void>? _closeFuture;

  Future<void> close() {
    return _closeFuture ??= Future.wait<void>([
      Future<void>.sync(questionProgressStore.close),
      Future<void>.sync(settingsStore.close),
    ]);
  }
}
