import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice/practice_session.dart';
import 'package:pm_app/src/practice/practice_summary.dart';
import 'package:pm_app/src/practice/session_answers.dart';
import 'package:pm_app/src/practice_summary/practice_summary_page.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../fixtures/question_fixtures.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('renders score, elapsed time, and question results', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final questions = buildQuestions();
    final summary = PracticeSummary(
      session: PracticeSession.fromQuestions(
        questions: questions,
        answers: SessionAnswers(
          selectedOptionsByQuestionCode: {
            questions.first.code: QuestionOption.b,
            questions.last.code: QuestionOption.b,
          },
          correctAttemptCount: 1,
          incorrectAttemptCount: 1,
        ),
      ),
      elapsedTime: const Duration(minutes: 1, seconds: 1),
    );

    await tester.pumpLocalizedPage(
      PracticeSummaryPage(
        summary: summary,
        returnDestination: PracticeSummaryReturnDestination.home,
      ),
    );

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
    expect(find.bySemanticsLabel('Correcta'), findsOneWidget);
    expect(find.bySemanticsLabel('Incorrecta'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('labels unanswered results and the history destination', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final question = buildQuestions().first;
    final summary = PracticeSummary(
      session: PracticeSession.fromQuestions(questions: [question]),
      elapsedTime: Duration.zero,
    );

    await tester.pumpLocalizedPage(
      PracticeSummaryPage(
        summary: summary,
        returnDestination: PracticeSummaryReturnDestination.answerHistory,
      ),
    );

    expect(find.text('${question.code} · Sin responder'), findsOneWidget);
    expect(find.bySemanticsLabel('Sin responder'), findsOneWidget);
    expect(find.text('Volver al historial'), findsOneWidget);
    expect(find.text('Volver al inicio'), findsNothing);
    semantics.dispose();
  });
}
