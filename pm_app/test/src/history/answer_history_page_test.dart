import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../fixtures/question_fixtures.dart';
import '../../helpers/fake_question_progress_store.dart';
import '../../helpers/fake_settings_store.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows recent answers and opens one-question practice', (
    tester,
  ) async {
    final progressStore = FakeQuestionProgressStore();
    final settingsStore = FakeSettingsStore(answerShuffleEnabled: false);
    addTearDown(progressStore.close);
    addTearDown(settingsStore.close);
    await progressStore.recordAnswer(
      QuestionAnswerRecord(
        questionCode: '1A01001',
        section: '1A',
        selectedOption: QuestionOption.a,
        correctOption: QuestionOption.b,
        answeredAt: DateTime(2026, 8, 2, 10),
      ),
    );
    await progressStore.recordAnswer(
      QuestionAnswerRecord(
        questionCode: '1A01002',
        section: '1A',
        selectedOption: QuestionOption.a,
        correctOption: QuestionOption.a,
        answeredAt: DateTime(2026, 8, 2, 11),
      ),
    );

    await tester.pumpApp(
      loadQuestions: (_) async => buildQuestions(),
      questionProgressStore: progressStore,
      settingsStore: settingsStore,
    );

    await tester.tap(find.byKey(const ValueKey('answer-history-button')));
    await tester.pumpAndSettle();

    expect(find.text('Historial'), findsOneWidget);
    expect(find.text('dom, 2 ago 2026'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('answer-history-date-header-dom, 2 ago 2026'),
        ),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(find.text('Segunda pregunta'), findsOneWidget);
    expect(find.text('Primera pregunta'), findsOneWidget);
    expect(find.text('Elegida: Respuesta A'), findsNWidgets(2));
    expect(find.textContaining('Correcta:'), findsNothing);
    expect(find.text('1A01002 · 11:00'), findsOneWidget);
    expect(find.text('11:00'), findsNothing);
    final selectedAnswerText = tester.widget<Text>(
      find.text('Elegida: Respuesta A').first,
    );
    expect(selectedAnswerText.maxLines, 1);
    expect(selectedAnswerText.overflow, TextOverflow.ellipsis);
    expect(find.text('dom, 2 ago 2026 11:00'), findsNothing);

    expect(
      tester.getTopLeft(find.text('Segunda pregunta')).dy,
      lessThan(tester.getTopLeft(find.text('Primera pregunta')).dy),
    );

    await tester.tap(find.text('Segunda pregunta'));
    await tester.pumpAndSettle();

    expect(find.text('Segunda pregunta'), findsOneWidget);
    expect(find.text('Primera pregunta'), findsNothing);
    expect(find.text('Pregunta 1 de 1'), findsOneWidget);
    expect(find.text('Todas'), findsNothing);
    expect(find.text('Simulacro'), findsNothing);
    expect(find.byKey(const ValueKey('simulacro-elapsed-time')), findsNothing);
    expect(
      find.byKey(const ValueKey('question-navigation-app-bar-button')),
      findsNothing,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('answer-A'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('answer-B'))).dy),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('answer-B'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('answer-C'))).dy),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('answer-C'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('answer-D'))).dy),
    );

    await tester.tap(find.byKey(const ValueKey('answer-A')));
    await tester.pumpAndSettle();
    expect(find.text('Finalizar'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('next-question-button')));
    await tester.pumpAndSettle();

    expect(find.text('Historial'), findsOneWidget);
    expect(find.text('Resumen'), findsNothing);
  });

  testWidgets('keeps canonical answer text after shuffled practice', (
    tester,
  ) async {
    final progressStore = FakeQuestionProgressStore();
    addTearDown(progressStore.close);

    await tester.pumpApp(
      loadQuestions: (_) async => [buildQuestions().first],
      questionProgressStore: progressStore,
    );
    await tester.tap(find.byKey(const ValueKey('home-unanswered-stat')));
    await tester.pumpAndSettle();

    final canonicalAnswer = find.byKey(const ValueKey('answer-A'));
    expect(
      find.descendant(of: canonicalAnswer, matching: find.text('Respuesta A')),
      findsOneWidget,
    );
    await tester.tap(canonicalAnswer);
    await tester.pumpAndSettle();

    Navigator.of(tester.element(find.text('Primera pregunta'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('answer-history-button')));
    await tester.pumpAndSettle();

    expect(find.text('Elegida: Respuesta A'), findsOneWidget);
  });

  testWidgets('displays history entries whose question is unavailable', (
    tester,
  ) async {
    final progressStore = FakeQuestionProgressStore();
    addTearDown(progressStore.close);
    await progressStore.recordAnswer(
      QuestionAnswerRecord(
        questionCode: 'missing',
        section: '1A',
        selectedOption: QuestionOption.c,
        correctOption: QuestionOption.a,
        answeredAt: DateTime(2026, 8, 2, 11),
      ),
    );

    await tester.pumpApp(
      loadQuestions: (_) async => buildQuestions(),
      questionProgressStore: progressStore,
    );
    await tester.tap(find.byKey(const ValueKey('answer-history-button')));
    await tester.pumpAndSettle();

    expect(find.text('Pregunta no disponible'), findsOneWidget);
    expect(find.text('Elegida: C'), findsOneWidget);
    expect(find.text('missing · 11:00'), findsOneWidget);
  });

  testWidgets('shows a localized history failure and retries', (tester) async {
    final progressStore = FakeQuestionProgressStore();
    addTearDown(progressStore.close);

    await tester.pumpApp(
      loadQuestions: (_) async => buildQuestions(),
      questionProgressStore: progressStore,
    );
    await tester.tap(find.byKey(const ValueKey('answer-history-button')));
    await tester.pumpAndSettle();

    progressStore.emitSnapshotError(StateError('private storage details'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo cargar el historial.'), findsOneWidget);
    expect(find.textContaining('private storage details'), findsNothing);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Todavía no has respondido ninguna pregunta.'),
      findsOneWidget,
    );
  });
}
