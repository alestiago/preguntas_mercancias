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
}

Future<void> _startSimulacro(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('start-simulacro-button')));
  await tester.pumpAndSettle();
}
