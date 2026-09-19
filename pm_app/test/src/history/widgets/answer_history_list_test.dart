import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/history/bloc/answer_history_bloc.dart';
import 'package:pm_app/src/history/widgets/answer_history_list.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../../fixtures/question_fixtures.dart';
import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('renders and selects a question from the extracted list', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final question = buildQuestions().first;
    Question? selectedQuestion;
    final answer = QuestionAnswerRecord(
      questionCode: question.code,
      section: question.section,
      selectedOption: QuestionOption.a,
      correctOption: question.correctOption,
      answeredAt: DateTime(2026, 8, 2, 10),
    );

    await tester.pumpLocalizedPage(
      Scaffold(
        body: AnswerHistoryList(
          sections: [
            AnswerHistorySection(
              date: DateTime(2026, 8, 2),
              entries: [AnswerHistoryEntry(answer: answer, question: question)],
            ),
          ],
          onQuestionSelected: (value) => selectedQuestion = value,
        ),
      ),
    );

    expect(find.text('dom, 2 ago 2026'), findsOneWidget);
    expect(find.text(question.prompt), findsOneWidget);
    expect(find.bySemanticsLabel('Incorrecta'), findsOneWidget);
    await tester.tap(find.text(question.prompt));

    expect(selectedQuestion, same(question));
    semantics.dispose();
  });
}
