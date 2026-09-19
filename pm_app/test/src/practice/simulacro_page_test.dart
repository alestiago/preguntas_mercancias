import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../fixtures/question_fixtures.dart';
import '../../helpers/fake_question_progress_store.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('starts a thirty-question simulacro', (tester) async {
    final progressStore = FakeQuestionProgressStore();
    final questions = buildSimulacroQuestions();
    addTearDown(progressStore.close);
    await progressStore.recordAnswer(
      QuestionAnswerRecord(
        questionCode: questions.first.code,
        section: questions.first.section,
        selectedOption: QuestionOption.a,
        correctOption: QuestionOption.a,
      ),
    );

    await tester.pumpApp(
      loadQuestions: (_) async => questions,
      questionProgressStore: progressStore,
    );

    expect(
      find.byKey(const ValueKey('start-simulacro-button')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('start-simulacro-button')),
        matching: find.text('30'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('start-simulacro-button')));
    await tester.pumpAndSettle();

    expect(find.text('Simulacro'), findsOneWidget);
    expect(find.text('Pregunta 1 de 30'), findsOneWidget);
    expect(find.text('0/0 (0%)'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Todas'), findsNothing);

    await tester.pump(const Duration(seconds: 61));

    expect(find.text('01:01'), findsOneWidget);
  });

  testWidgets('opens navigation drawer and jumps to a question', (
    tester,
  ) async {
    final progressStore = FakeQuestionProgressStore();
    addTearDown(progressStore.close);

    await tester.pumpApp(
      loadQuestions: (_) async => buildSimulacroQuestions(),
      questionProgressStore: progressStore,
    );

    await _startSimulacro(tester);
    await tester.tap(
      find.byKey(const ValueKey('question-navigation-open-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Preguntas'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('question-navigation-tile-2')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('question-navigation-tile-2')));
    await tester.pumpAndSettle();

    expect(find.text('Preguntas'), findsNothing);
    expect(find.text('Pregunta 2 de 30'), findsOneWidget);
  });

  testWidgets('exits an unanswered simulacro without confirmation', (
    tester,
  ) async {
    final progressStore = FakeQuestionProgressStore();
    addTearDown(progressStore.close);

    await tester.pumpApp(
      loadQuestions: (_) async => buildSimulacroQuestions(),
      questionProgressStore: progressStore,
    );

    await _startSimulacro(tester);
    await tester.tap(find.byKey(const ValueKey('exit-practice-button')));
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(find.text('¿Seguro que quieres salir del simulacro?'), findsNothing);
  });

  testWidgets('cancels exiting an answered simulacro', (tester) async {
    final progressStore = FakeQuestionProgressStore();
    addTearDown(progressStore.close);

    await tester.pumpApp(
      loadQuestions: (_) async => buildSimulacroQuestions(),
      questionProgressStore: progressStore,
    );

    await _startSimulacro(tester);
    await tester.tap(find.byKey(const ValueKey('answer-A')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exit-practice-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('¿Seguro que quieres salir del simulacro?'),
      findsOneWidget,
    );
    expect(find.text('Perderás el progreso de este intento.'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Simulacro'), findsOneWidget);
    expect(find.text('Pregunta 1 de 30'), findsOneWidget);
  });

  testWidgets('confirmed exit leaves an answered simulacro', (tester) async {
    final progressStore = FakeQuestionProgressStore();
    addTearDown(progressStore.close);

    await tester.pumpApp(
      loadQuestions: (_) async => buildSimulacroQuestions(),
      questionProgressStore: progressStore,
    );

    await _startSimulacro(tester);
    await tester.tap(find.byKey(const ValueKey('answer-A')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exit-practice-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(find.text('Pregunta 1 de 30'), findsNothing);
    expect(find.byKey(const ValueKey('exit-practice-button')), findsNothing);
  });

  testWidgets('system back uses the same answered-exit confirmation', (
    tester,
  ) async {
    final progressStore = FakeQuestionProgressStore();
    addTearDown(progressStore.close);

    await tester.pumpApp(
      loadQuestions: (_) async => buildSimulacroQuestions(),
      questionProgressStore: progressStore,
    );

    await _startSimulacro(tester);
    await tester.tap(find.byKey(const ValueKey('answer-A')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
      find.text('¿Seguro que quieres salir del simulacro?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Pregunta 1 de 30'), findsOneWidget);
  });

  testWidgets('cannot exit while an answer is being saved', (tester) async {
    final progressStore = _SlowQuestionProgressStore();
    addTearDown(progressStore.close);

    await tester.pumpApp(
      loadQuestions: (_) async => buildSimulacroQuestions(),
      questionProgressStore: progressStore,
    );

    await _startSimulacro(tester);
    await tester.tap(find.byKey(const ValueKey('answer-A')));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('exit-practice-button')));
    await tester.pump();

    expect(find.text('Pregunta 1 de 30'), findsOneWidget);
    expect(find.text('¿Seguro que quieres salir del simulacro?'), findsNothing);

    progressStore.completePendingRecords();
    await tester.pumpAndSettle();
  });

  testWidgets('finishes with skipped questions represented as unanswered', (
    tester,
  ) async {
    final progressStore = FakeQuestionProgressStore();
    addTearDown(progressStore.close);

    await tester.pumpApp(
      loadQuestions: (_) async => buildSimulacroQuestions(),
      questionProgressStore: progressStore,
    );

    await _startSimulacro(tester);
    await tester.tap(
      find.byKey(const ValueKey('question-navigation-open-button')),
    );
    await tester.pumpAndSettle();
    final lastQuestion = find.byKey(
      const ValueKey('question-navigation-tile-30'),
    );
    await tester.ensureVisible(lastQuestion);
    await tester.pumpAndSettle();
    await tester.tap(lastQuestion);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('answer-A')));
    await tester.pumpAndSettle();

    expect(find.text('Finalizar'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('next-question-button')));
    await tester.pumpAndSettle();

    expect(find.text('Resultado del simulacro'), findsOneWidget);
    expect(find.text('1/30 (3%)'), findsOneWidget);
    expect(find.textContaining('Sin responder'), findsWidgets);

    final backToHome = find.byKey(const ValueKey('back-to-home-button'));
    await tester.scrollUntilVisible(
      backToHome,
      500,
      scrollable: find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(backToHome);
    await tester.pumpAndSettle();
    expect(find.text('Tu progreso'), findsOneWidget);
  });
}

Future<void> _startSimulacro(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('start-simulacro-button')));
  await tester.pumpAndSettle();
}

final class _SlowQuestionProgressStore extends FakeQuestionProgressStore {
  final List<Completer<void>> _pendingRecords = [];

  @override
  Future<void> recordAnswer(QuestionAnswerRecord answer) async {
    final completer = Completer<void>();
    _pendingRecords.add(completer);
    await completer.future;
    await super.recordAnswer(answer);
  }

  void completePendingRecords() {
    for (final completer in _pendingRecords) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }
}
