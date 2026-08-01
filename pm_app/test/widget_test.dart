import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/main.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

void main() {
  testWidgets('answers a question and advances to the next one', (
    tester,
  ) async {
    await tester.pumpWidget(
      PreguntasMercanciasApp(loadQuestions: (_) async => _questions),
    );
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
