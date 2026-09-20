import 'package:flutter/material.dart';
import 'package:pm_app/component_library.dart';
import 'package:pm_questions/pm_questions.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../../../support/fixture_factory.dart';
import '../../../../../support/use_case_frame.dart';

final answerFeedbackSwitcherComponent = WidgetbookComponent(
  name: 'AnswerFeedbackSwitcher',
  useCases: [
    WidgetbookUseCase(
      name: 'Interactive',
      builder: (context) {
        final answered = context.knobs.boolean(
          label: 'Answered',
          initialValue: true,
        );
        final selectedOption = context.knobs.object.segmented(
          label: 'Selected option',
          options: QuestionOption.values,
          initialOption: QuestionOption.a,
          labelBuilder: (option) => option.code,
        );
        final question = WidgetbookFixtures.question();

        return UseCaseFrame(
          builder: (_) => AnswerFeedbackSwitcher(
            answered: answered,
            question: question,
            answerPresentation: QuestionAnswerPresentation.inSourceOrder(
              question,
            ),
            selectedOption: answered ? selectedOption : null,
          ),
        );
      },
    ),
    WidgetbookUseCase(
      name: 'Correct',
      builder: (_) => _feedbackUseCase(QuestionOption.c),
    ),
    WidgetbookUseCase(
      name: 'Incorrect',
      builder: (_) => _feedbackUseCase(QuestionOption.a),
    ),
    WidgetbookUseCase(name: 'Hidden', builder: (_) => _feedbackUseCase(null)),
  ],
);

Widget _feedbackUseCase(QuestionOption? selectedOption) {
  final question = WidgetbookFixtures.question();
  return UseCaseFrame(
    builder: (_) => AnswerFeedbackSwitcher(
      answered: selectedOption != null,
      question: question,
      answerPresentation: QuestionAnswerPresentation.inSourceOrder(question),
      selectedOption: selectedOption,
    ),
  );
}
