import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../fixtures/question_fixtures.dart';
import '../../helpers/fake_question_progress_store.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows a localized load failure and retries', (tester) async {
    final progressStore = FakeQuestionProgressStore();
    var loadCount = 0;
    addTearDown(progressStore.close);

    await tester.pumpApp(
      loadQuestions: (_) async {
        loadCount += 1;
        if (loadCount == 1) {
          throw StateError('private loading details');
        }
        return buildQuestions();
      },
      questionProgressStore: progressStore,
    );

    expect(find.text('No se pudo cargar el progreso.'), findsOneWidget);
    expect(find.textContaining('private loading details'), findsNothing);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(loadCount, 2);
  });

  testWidgets('starts review practice from the review count', (tester) async {
    final progressStore = FakeQuestionProgressStore();
    final loadCalls = <String?>[];
    addTearDown(progressStore.close);
    await progressStore.recordAnswer(
      QuestionAnswerRecord(
        questionCode: '1B01001',
        section: '1B',
        selectedOption: QuestionOption.a,
        correctOption: QuestionOption.b,
      ),
    );

    await tester.pumpApp(
      loadQuestions: (section) {
        loadCalls.add(section);
        return loadReviewQuestions(section);
      },
      questionProgressStore: progressStore,
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-incorrect-stat')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('home-incorrect-stat')));
    await tester.pumpAndSettle();

    expect(find.text('Por repasar'), findsOneWidget);
    expect(find.text('Pregunta 1B'), findsOneWidget);
    expect(find.text('Pregunta 1A'), findsNothing);
    expect(find.text('Pregunta 1 de 1'), findsOneWidget);
    expect(loadCalls, [null]);

    await tester.tap(find.byKey(const ValueKey('answer-B')));
    await tester.pumpAndSettle();

    expect(find.text('Finalizar'), findsOneWidget);

    final nextButton = find.byKey(const ValueKey('next-question-button'));
    await tester.ensureVisible(nextButton);
    await tester.pumpAndSettle();
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-incorrect-stat')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('starts pending practice from the unanswered count', (
    tester,
  ) async {
    final progressStore = FakeQuestionProgressStore();
    final loadCalls = <String?>[];
    addTearDown(progressStore.close);
    await progressStore.recordAnswer(
      QuestionAnswerRecord(
        questionCode: '1A01001',
        section: '1A',
        selectedOption: QuestionOption.b,
        correctOption: QuestionOption.b,
      ),
    );

    await tester.pumpApp(
      loadQuestions: (section) {
        loadCalls.add(section);
        return loadReviewQuestions(section);
      },
      questionProgressStore: progressStore,
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-unanswered-stat')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('home-unanswered-stat')));
    await tester.pumpAndSettle();

    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('Pregunta 1B'), findsOneWidget);
    expect(find.text('Pregunta 1A'), findsNothing);
    expect(find.text('Pregunta 1 de 1'), findsOneWidget);
    expect(loadCalls, [null]);

    await tester.tap(find.byKey(const ValueKey('answer-B')));
    await tester.pumpAndSettle();

    expect(find.text('Finalizar'), findsOneWidget);

    final nextButton = find.byKey(const ValueKey('next-question-button'));
    await tester.ensureVisible(nextButton);
    await tester.pumpAndSettle();
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-unanswered-stat')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('starts pending practice with a ten-question batch', (
    tester,
  ) async {
    final progressStore = FakeQuestionProgressStore();
    final loadCalls = <String?>[];
    final questions = buildManyQuestions(15);
    addTearDown(progressStore.close);

    await tester.pumpApp(
      loadQuestions: (section) {
        loadCalls.add(section);
        return Future.value(
          section == null
              ? questions
              : questions
                    .where((question) => question.section == section)
                    .toList(growable: false),
        );
      },
      questionProgressStore: progressStore,
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-unanswered-stat')),
        matching: find.text('15'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('home-unanswered-stat')));
    await tester.pumpAndSettle();

    expect(find.text('Pregunta 1'), findsOneWidget);
    expect(find.text('Pregunta 1 de 15'), findsOneWidget);
    expect(loadCalls, [null]);

    for (var questionNumber = 1; questionNumber <= 5; questionNumber += 1) {
      await tester.tap(find.byKey(const ValueKey('answer-A')));
      await tester.pumpAndSettle();

      final nextButton = find.byKey(const ValueKey('next-question-button'));
      await tester.ensureVisible(nextButton);
      await tester.pumpAndSettle();
      await tester.tap(nextButton);
      await tester.pumpAndSettle();
    }

    expect(find.text('Pregunta 6'), findsOneWidget);
    expect(find.text('Pregunta 6 de 15'), findsOneWidget);
  });
}
