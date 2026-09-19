import 'package:flutter/material.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/theme/app_theme.dart';
import '../question_answer_presentation.dart';

class AnswerFeedbackSwitcher extends StatelessWidget {
  const AnswerFeedbackSwitcher({
    super.key,
    required this.answered,
    required this.question,
    required this.answerPresentation,
    required this.selectedOption,
  });

  final bool answered;
  final Question question;
  final QuestionAnswerPresentation answerPresentation;
  final QuestionOption? selectedOption;

  @override
  Widget build(BuildContext context) {
    final selectedOption = this.selectedOption;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: answered && selectedOption != null
          ? _AnswerFeedback(
              key: ValueKey(selectedOption),
              question: question,
              answerPresentation: answerPresentation,
              selectedOption: selectedOption,
            )
          : const SizedBox.shrink(),
    );
  }
}

class _AnswerFeedback extends StatelessWidget {
  const _AnswerFeedback({
    super.key,
    required this.question,
    required this.answerPresentation,
    required this.selectedOption,
  });

  final Question question;
  final QuestionAnswerPresentation answerPresentation;
  final QuestionOption selectedOption;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isCorrect = question.isCorrect(selectedOption);
    final correctDisplayOption = answerPresentation.displayOptionFor(
      question.correctOption,
    );
    final feedbackTitle = isCorrect
        ? localizations.correctAnswerFeedbackTitle
        : localizations.incorrectAnswerFeedbackTitle;
    final correctAnswerDescription = localizations.correctAnswer(
      correctDisplayOption.code,
      question.correctAnswer.text,
    );
    final normDescription = localizations.normReference(question.norma);
    final feedbackStyle = _AnswerFeedbackStyle.forResult(
      colorScheme: Theme.of(context).colorScheme,
      resultColors: AppResultColors.of(context),
      isCorrect: isCorrect,
    );

    return Semantics(
      container: true,
      liveRegion: true,
      label: '$feedbackTitle. $correctAnswerDescription. $normDescription',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: feedbackStyle.backgroundColor,
            border: Border.all(color: feedbackStyle.borderColor),
            borderRadius: BorderRadius.circular(AppLayout.cardRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AnswerFeedbackHeader(
                  title: feedbackTitle,
                  icon: feedbackStyle.icon,
                  foregroundColor: feedbackStyle.foregroundColor,
                ),
                const SizedBox(height: 10),
                _CorrectAnswerDetails(
                  correctAnswerDescription: correctAnswerDescription,
                  normDescription: normDescription,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerFeedbackHeader extends StatelessWidget {
  const _AnswerFeedbackHeader({
    required this.title,
    required this.icon,
    required this.foregroundColor,
  });

  final String title;
  final IconData icon;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: foregroundColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 18,
              fontWeight: AppTypography.strongWeight,
            ),
          ),
        ),
      ],
    );
  }
}

class _CorrectAnswerDetails extends StatelessWidget {
  const _CorrectAnswerDetails({
    required this.correctAnswerDescription,
    required this.normDescription,
  });

  final String correctAnswerDescription;
  final String normDescription;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          correctAnswerDescription,
          style: const TextStyle(fontWeight: FontWeight.w600, height: 1.25),
        ),
        const SizedBox(height: 8),
        Text(
          normDescription,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }
}

final class _AnswerFeedbackStyle {
  const _AnswerFeedbackStyle({
    required this.icon,
    required this.borderColor,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final Color borderColor;
  final Color backgroundColor;
  final Color foregroundColor;

  factory _AnswerFeedbackStyle.forResult({
    required ColorScheme colorScheme,
    required AppResultColors resultColors,
    required bool isCorrect,
  }) {
    return isCorrect
        ? _AnswerFeedbackStyle(
            icon: Icons.check_circle,
            borderColor: resultColors.correct,
            backgroundColor: resultColors.correctContainer,
            foregroundColor: resultColors.onCorrectContainer,
          )
        : _AnswerFeedbackStyle(
            icon: Icons.cancel,
            borderColor: colorScheme.error,
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
          );
  }
}
