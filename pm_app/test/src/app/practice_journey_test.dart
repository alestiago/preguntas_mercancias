import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/question_fixtures.dart';
import '../../helpers/fake_question_progress_store.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('answers questions and updates home progress', (tester) async {
    final progressStore = FakeQuestionProgressStore();
    addTearDown(progressStore.close);

    await tester.pumpApp(
      loadQuestions: (_) async => buildQuestions(),
      questionProgressStore: progressStore,
    );

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(find.text('2 preguntas en el banco'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-unanswered-count')), findsOneWidget);
    expect(find.byKey(const ValueKey('start-practice-button')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home-unanswered-stat')));
    await tester.pumpAndSettle();

    expect(find.text('Primera pregunta'), findsOneWidget);
    final answerButtons = _answerButtonsFinder();
    expect(answerButtons, findsNWidgets(4));
    for (final option in ['A', 'B', 'C', 'D']) {
      expect(
        find.descendant(of: answerButtons, matching: find.text(option)),
        findsOneWidget,
      );
    }

    await tester.tap(find.byKey(const ValueKey('answer-A')));
    await tester.pumpAndSettle();

    expect(find.text('Incorrecta'), findsOneWidget);
    expect(find.textContaining('Respuesta correcta:'), findsOneWidget);
    expect(find.text('0/1 (0%)'), findsOneWidget);

    final nextButton = find.byKey(const ValueKey('next-question-button'));
    await tester.ensureVisible(nextButton);
    await tester.pumpAndSettle();
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(find.text('Segunda pregunta'), findsOneWidget);

    Navigator.of(tester.element(find.text('Segunda pregunta'))).pop();
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-incorrect-stat')),
        matching: find.text('1'),
      ),
      findsOneWidget,
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
    await tester.tap(find.byKey(const ValueKey('answer-A')));
    await tester.pumpAndSettle();

    expect(find.text('Finalizar'), findsOneWidget);
    expect(find.text('1/1 (100%)'), findsOneWidget);

    await tester.ensureVisible(nextButton);
    await tester.pumpAndSettle();
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso'), findsOneWidget);
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
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-unanswered-stat')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
  });
}

Finder _answerButtonsFinder() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return widget is OutlinedButton &&
        key is ValueKey<String> &&
        key.value.startsWith('answer-');
  });
}
