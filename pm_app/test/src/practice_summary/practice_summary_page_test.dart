import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice_summary/practice_summary_page.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../fixtures/question_fixtures.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('renders score, elapsed time, and question results', (
    tester,
  ) async {
    final questions = buildQuestions();
    final summary = PracticeSummary(
      questions: questions,
      selectedOptionsByQuestionCode: {
        questions.first.code: QuestionOption.b,
        questions.last.code: QuestionOption.b,
      },
      correctAttemptCount: 1,
      incorrectAttemptCount: 1,
      elapsedTime: const Duration(minutes: 1, seconds: 1),
    );

    await tester.pumpLocalizedPage(PracticeSummaryPage(summary: summary));

    expect(find.text('Resultado del simulacro'), findsOneWidget);
    expect(find.text('1/2 (50%)'), findsOneWidget);
    expect(find.text('Tiempo empleado: 01:01'), findsOneWidget);
    expect(find.text('Detalle de respuestas'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('summary-question-1A01001')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('summary-question-1A01002')),
      findsOneWidget,
    );
    expect(find.text('Volver al inicio'), findsOneWidget);
  });
}
