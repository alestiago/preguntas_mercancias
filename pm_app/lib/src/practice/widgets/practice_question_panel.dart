import 'package:flutter/material.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/theme/app_theme.dart';
import '../question_answer_presentation.dart';

class PracticeQuestionPanel extends StatelessWidget {
  const PracticeQuestionPanel({
    super.key,
    required this.question,
    required this.answerPresentation,
    required this.selectedOption,
    required this.onAnswer,
  });

  final Question question;
  final QuestionAnswerPresentation answerPresentation;
  final QuestionOption? selectedOption;
  final ValueChanged<QuestionOption> onAnswer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppLayout.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              question.prompt,
              style: textTheme.titleLarge?.copyWith(
                height: 1.25,
                fontWeight: AppTypography.emphasizedWeight,
              ),
            ),
            const SizedBox(height: 20),
            for (
              var index = 0;
              index < answerPresentation.answers.length;
              index += 1
            ) ...[
              _AnswerOptionButton(
                answer: answerPresentation.answers[index],
                displayOption: answerPresentation.displayOptionFor(
                  answerPresentation.answers[index].option,
                ),
                correctOption: question.correctOption,
                selectedOption: selectedOption,
                onPressed: () =>
                    onAnswer(answerPresentation.answers[index].option),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnswerOptionButton extends StatelessWidget {
  const _AnswerOptionButton({
    required this.answer,
    required this.displayOption,
    required this.correctOption,
    required this.selectedOption,
    required this.onPressed,
  });

  final QuestionAnswer answer;
  final QuestionOption displayOption;
  final QuestionOption correctOption;
  final QuestionOption? selectedOption;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final answered = selectedOption != null;
    final selected = selectedOption == answer.option;
    final correct = correctOption == answer.option;
    final localizations = AppLocalizations.of(context);
    final optionStyle = _AnswerOptionStyle.forState(
      colorScheme: colorScheme,
      resultColors: AppResultColors.of(context),
      answered: answered,
      selected: selected,
      correct: correct,
    );

    final semanticsParts = [
      localizations.answerOptionSemantics(displayOption.code, answer.text),
      if (selected) localizations.selectedAnswerSemantics,
      if (answered && correct) localizations.correctAnswerFeedbackTitle,
      if (answered && selected && !correct)
        localizations.incorrectAnswerFeedbackTitle,
    ];

    return Semantics(
      button: true,
      enabled: !answered,
      selected: selected,
      label: semanticsParts.join('. '),
      excludeSemantics: true,
      onTap: answered ? null : onPressed,
      child: OutlinedButton(
        key: ValueKey('answer-${answer.option.code}'),
        onPressed: answered ? null : onPressed,
        style: OutlinedButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
          backgroundColor: optionStyle.backgroundColor,
          disabledBackgroundColor: optionStyle.backgroundColor,
          foregroundColor: optionStyle.foregroundColor,
          disabledForegroundColor: optionStyle.foregroundColor,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          side: BorderSide(
            color: optionStyle.borderColor,
            width: answered ? 1.4 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppLayout.cardRadius),
          ),
        ),
        child: _AnswerOptionButtonContent(
          answer: answer,
          displayOption: displayOption,
          selected: selected,
          correct: answered && correct,
          trailingIcon: optionStyle.trailingIcon,
        ),
      ),
    );
  }
}

class _AnswerOptionButtonContent extends StatelessWidget {
  const _AnswerOptionButtonContent({
    required this.answer,
    required this.displayOption,
    required this.selected,
    required this.correct,
    required this.trailingIcon,
  });

  final QuestionAnswer answer;
  final QuestionOption displayOption;
  final bool selected;
  final bool correct;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _OptionBadge(
          option: displayOption,
          selected: selected,
          correct: correct,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            answer.text,
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.25),
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 10),
          Icon(trailingIcon),
        ],
      ],
    );
  }
}

class _OptionBadge extends StatelessWidget {
  const _OptionBadge({
    required this.option,
    required this.selected,
    required this.correct,
  });

  final QuestionOption option;
  final bool selected;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = correct || selected
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = correct || selected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return CircleAvatar(
      radius: 16,
      backgroundColor: backgroundColor,
      child: Text(
        option.code,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 14,
          fontWeight: AppTypography.strongWeight,
        ),
      ),
    );
  }
}

final class _AnswerOptionStyle {
  const _AnswerOptionStyle({
    required this.borderColor,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.trailingIcon,
  });

  final Color borderColor;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? trailingIcon;

  factory _AnswerOptionStyle.forState({
    required ColorScheme colorScheme,
    required AppResultColors resultColors,
    required bool answered,
    required bool selected,
    required bool correct,
  }) {
    if (answered && correct) {
      return _AnswerOptionStyle(
        borderColor: resultColors.correct,
        backgroundColor: resultColors.correctContainer,
        foregroundColor: resultColors.onCorrectContainer,
        trailingIcon: Icons.check_circle,
      );
    }

    if (answered && selected) {
      return _AnswerOptionStyle(
        borderColor: colorScheme.error,
        backgroundColor: colorScheme.errorContainer,
        foregroundColor: colorScheme.onErrorContainer,
        trailingIcon: Icons.cancel,
      );
    }

    return _AnswerOptionStyle(
      borderColor: colorScheme.outlineVariant,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      trailingIcon: null,
    );
  }
}
