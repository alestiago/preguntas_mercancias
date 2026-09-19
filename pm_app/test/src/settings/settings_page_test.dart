import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../fixtures/question_fixtures.dart';
import '../../helpers/fake_question_progress_store.dart';
import '../../helpers/fake_settings_store.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows version, persists shuffle, and resets progress', (
    tester,
  ) async {
    final progressStore = FakeQuestionProgressStore();
    addTearDown(progressStore.close);
    final settingsStore = FakeSettingsStore();
    addTearDown(settingsStore.close);
    await progressStore.recordAnswer(
      QuestionAnswerRecord(
        questionCode: '1A01001',
        section: '1A',
        selectedOption: QuestionOption.b,
        correctOption: QuestionOption.b,
      ),
    );
    await progressStore.recordAnswer(
      QuestionAnswerRecord(
        questionCode: '1A01002',
        section: '1A',
        selectedOption: QuestionOption.b,
        correctOption: QuestionOption.a,
      ),
    );

    await tester.pumpApp(
      loadQuestions: (_) async => buildQuestions(),
      questionProgressStore: progressStore,
      settingsStore: settingsStore,
    );

    expect(find.byKey(const ValueKey('settings-button')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-correct-stat')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-incorrect-stat')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Versión'), findsOneWidget);
    expect(find.text('1.0.0+1'), findsOneWidget);
    expect(find.byKey(const ValueKey('reset-progress-tile')), findsOneWidget);

    final shuffleSwitchFinder = find.byKey(
      const ValueKey('shuffle-answers-switch'),
    );
    expect(shuffleSwitchFinder, findsOneWidget);
    expect(tester.widget<SwitchListTile>(shuffleSwitchFinder).value, isTrue);

    await tester.tap(shuffleSwitchFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(shuffleSwitchFinder).value, isFalse);
    expect(await settingsStore.loadAnswerShuffleEnabled(), isFalse);

    await tester.tap(find.byKey(const ValueKey('reset-progress-tile')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Se borrarán tus respuestas y estadísticas. Esta acción no se puede deshacer.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('confirm-reset-progress-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Progreso reiniciado'), findsOneWidget);
    expect(progressStore.recordedAnswers, isEmpty);

    Navigator.of(tester.element(find.text('Ajustes'))).pop();
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-correct-stat')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-incorrect-stat')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-unanswered-stat')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows reset failures', (tester) async {
    final error = StateError('Clear failed.');
    final progressStore = _FailingClearProgressStore(error);
    addTearDown(progressStore.close);

    await tester.pumpApp(
      loadQuestions: (_) async => buildQuestions(),
      questionProgressStore: progressStore,
    );
    await tester.tap(find.byKey(const ValueKey('settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reset-progress-tile')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('confirm-reset-progress-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('No se pudo reiniciar el progreso.'), findsOneWidget);
    expect(progressStore.clearCallCount, 1);
  });
}

final class _FailingClearProgressStore extends FakeQuestionProgressStore {
  _FailingClearProgressStore(this.error);

  final Object error;
  int clearCallCount = 0;

  @override
  Future<void> clear() async {
    clearCallCount += 1;
    throw error;
  }
}
