import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/main.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import 'helpers/fake_question_progress_store.dart';

void main() {
  testWidgets('answers a question and advances to the next one', (
    tester,
  ) async {
    final progressStore = FakeQuestionProgressStore();
    addTearDown(progressStore.close);

    await tester.pumpWidget(
      PreguntasMercanciasApp(
        loadQuestions: (_) async => _questions,
        questionProgressStore: progressStore,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(find.text('2 preguntas en el banco'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-unanswered-count')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('start-practice-button')));
    await tester.pumpAndSettle();

    expect(find.text('Primera pregunta'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('answer-A')));
    await tester.pumpAndSettle();

    expect(find.text('Incorrecta'), findsOneWidget);
    expect(find.textContaining('Respuesta correcta: B.'), findsOneWidget);

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

    await tester.tap(find.byKey(const ValueKey('start-practice-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('answer-B')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(nextButton);
    await tester.pumpAndSettle();
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('answer-A')));
    await tester.pumpAndSettle();

    Navigator.of(tester.element(find.text('Segunda pregunta'))).pop();
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-correct-stat')),
        matching: find.text('2'),
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
  });
}

final _questions = [
  Question(
    code: '1A01001',
    section: '1A',
    prompt: 'Primera pregunta',
    answers: const [
      QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
      QuestionAnswer(option: QuestionOption.b, text: 'Respuesta B'),
      QuestionAnswer(option: QuestionOption.c, text: 'Respuesta C'),
      QuestionAnswer(option: QuestionOption.d, text: 'Respuesta D'),
    ],
    correctOption: QuestionOption.b,
    norma: 'Norma primera',
  ),
  Question(
    code: '1A01002',
    section: '1A',
    prompt: 'Segunda pregunta',
    answers: const [
      QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
      QuestionAnswer(option: QuestionOption.b, text: 'Respuesta B'),
      QuestionAnswer(option: QuestionOption.c, text: 'Respuesta C'),
      QuestionAnswer(option: QuestionOption.d, text: 'Respuesta D'),
    ],
    correctOption: QuestionOption.a,
    norma: 'Norma segunda',
  ),
];
