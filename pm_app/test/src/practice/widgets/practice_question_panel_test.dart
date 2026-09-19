import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice/question_answer_presentation.dart';
import 'package:pm_app/src/practice/widgets/practice_question_panel.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../../fixtures/question_fixtures.dart';

void main() {
  testWidgets('reports the canonical option selected from the panel', (
    tester,
  ) async {
    final question = buildQuestions().first;
    QuestionOption? selectedOption;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PracticeQuestionPanel(
            question: question,
            answerPresentation: QuestionAnswerPresentation.inSourceOrder(
              question,
            ),
            selectedOption: null,
            onAnswer: (option) => selectedOption = option,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('answer-B')));

    expect(selectedOption, QuestionOption.b);
  });
}
