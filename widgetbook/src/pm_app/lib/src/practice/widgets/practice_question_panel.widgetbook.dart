import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pm_app/component_library.dart';
import 'package:pm_questions/pm_questions.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../../../support/callback_notification.dart';
import '../../../../../support/fixture_factory.dart';
import '../../../../../support/use_case_frame.dart';

final practiceQuestionPanelComponent = WidgetbookComponent(
  name: 'PracticeQuestionPanel',
  useCases: [
    WidgetbookUseCase(
      name: 'Interactive',
      builder: (context) {
        final shuffled = context.knobs.boolean(
          label: 'Shuffle answers',
          initialValue: false,
        );
        final selectedOption = context.knobs.objectOrNull.dropdown(
          label: 'Selected option',
          options: QuestionOption.values,
          labelBuilder: (option) => option.code,
        );

        return _InteractiveQuestionPanel(
          key: ValueKey('$shuffled-$selectedOption'),
          shuffled: shuffled,
          initialSelectedOption: selectedOption,
        );
      },
    ),
    WidgetbookUseCase(
      name: 'Long content',
      builder: (_) => const _InteractiveQuestionPanel(longContent: true),
    ),
  ],
);

class _InteractiveQuestionPanel extends StatefulWidget {
  const _InteractiveQuestionPanel({
    super.key,
    this.shuffled = false,
    this.initialSelectedOption,
    this.longContent = false,
  });

  final bool shuffled;
  final QuestionOption? initialSelectedOption;
  final bool longContent;

  @override
  State<_InteractiveQuestionPanel> createState() =>
      _InteractiveQuestionPanelState();
}

class _InteractiveQuestionPanelState extends State<_InteractiveQuestionPanel> {
  late QuestionOption? _selectedOption = widget.initialSelectedOption;

  @override
  Widget build(BuildContext context) {
    final question = WidgetbookFixtures.question(
      prompt: widget.longContent
          ? 'En un supuesto de transporte nacional con varias operaciones de carga, descarga y tránsito, ¿qué documentación debe conservar el conductor para acreditar el cumplimiento de todas las obligaciones aplicables durante el trayecto completo?'
          : null,
    );
    final presentation = QuestionAnswerPresentation.forSession(
      question,
      shuffleAnswers: widget.shuffled,
      random: Random(7),
    );

    return UseCaseFrame(
      builder: (context) => PracticeQuestionPanel(
        question: question,
        answerPresentation: presentation,
        selectedOption: _selectedOption,
        onAnswer: (option) {
          setState(() => _selectedOption = option);
          showCallbackNotification(
            context,
            'onAnswer',
            'option ${option.code}',
          );
        },
      ),
    );
  }
}
