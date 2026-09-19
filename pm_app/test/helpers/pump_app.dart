import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/app.dart';
import 'package:pm_app/l10n/app_localizations.dart';
import 'package:pm_app/src/app/theme/app_theme.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import 'fake_settings_store.dart';

typedef TestQuestionLoader = Future<List<Question>> Function(String? section);

extension PumpApp on WidgetTester {
  Future<void> pumpApp({
    required TestQuestionLoader loadQuestions,
    required QuestionProgressStore questionProgressStore,
    SettingsStore? settingsStore,
  }) async {
    final resolvedSettingsStore = settingsStore ?? FakeSettingsStore();
    if (settingsStore == null) {
      addTearDown(resolvedSettingsStore.close);
    }

    await pumpWidget(
      PreguntasMercanciasApp(
        dependencies: AppDependencies(
          questionProgressStore: questionProgressStore,
          settingsStore: resolvedSettingsStore,
        ),
        loadQuestions: loadQuestions,
      ),
    );
    await pumpAndSettle();
  }

  Future<void> pumpLocalizedPage(Widget page) async {
    await pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        home: page,
      ),
    );
    await pumpAndSettle();
  }
}
