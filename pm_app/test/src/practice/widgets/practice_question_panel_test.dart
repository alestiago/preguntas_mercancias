import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/app/theme/app_theme.dart';
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
        theme: AppTheme.light,
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

  testWidgets('uses semantic theme colors for answer results', (tester) async {
    final question = buildQuestions().first;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PracticeQuestionPanel(
            question: question,
            answerPresentation: QuestionAnswerPresentation.inSourceOrder(
              question,
            ),
            selectedOption: QuestionOption.a,
            onAnswer: (_) {},
          ),
        ),
      ),
    );

    final theme = AppTheme.light;
    final resultColors = theme.extension<AppResultColors>()!;
    final correctButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('answer-B')),
    );
    final incorrectButton = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('answer-A')),
    );
    const disabled = {WidgetState.disabled};

    expect(
      correctButton.style?.backgroundColor?.resolve(disabled),
      resultColors.correctContainer,
    );
    expect(
      incorrectButton.style?.backgroundColor?.resolve(disabled),
      theme.colorScheme.errorContainer,
    );
  });
}
