import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/l10n/app_localizations.dart';
import 'package:pm_app/main.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

typedef TestQuestionLoader = Future<List<Question>> Function(String? section);

extension PumpApp on WidgetTester {
  Future<void> pumpApp({
    required TestQuestionLoader loadQuestions,
    required QuestionProgressStore questionProgressStore,
    SettingsStore? settingsStore,
  }) async {
    await pumpWidget(
      PreguntasMercanciasApp(
        loadQuestions: loadQuestions,
        questionProgressStore: questionProgressStore,
        settingsStore: settingsStore,
      ),
    );
    await pumpAndSettle();
  }

  Future<void> pumpLocalizedPage(Widget page) async {
    await pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF136F63)),
          useMaterial3: true,
        ),
        home: page,
      ),
    );
    await pumpAndSettle();
  }
}
