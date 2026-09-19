import 'package:flutter/material.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/theme/app_theme.dart';

class PracticeQuestionHeader extends StatelessWidget {
  const PracticeQuestionHeader({
    super.key,
    required this.question,
    required this.currentQuestionNumber,
    required this.questionCount,
    required this.onOpenQuestionNavigator,
  });

  final Question question;
  final int currentQuestionNumber;
  final int questionCount;
  final VoidCallback? onOpenQuestionNavigator;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);
    final progressLabel = localizations.questionProgress(
      currentQuestionNumber,
      questionCount,
    );

    return Row(
      children: [
        Text(
          question.code,
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        _QuestionProgressLabel(
          label: progressLabel,
          onOpenQuestionNavigator: onOpenQuestionNavigator,
        ),
      ],
    );
  }
}

class _QuestionProgressLabel extends StatelessWidget {
  const _QuestionProgressLabel({
    required this.label,
    required this.onOpenQuestionNavigator,
  });

  final String label;
  final VoidCallback? onOpenQuestionNavigator;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);
    final labelStyle = textTheme.labelLarge?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: onOpenQuestionNavigator == null ? null : FontWeight.w700,
    );

    if (onOpenQuestionNavigator == null) {
      return Text(label, style: labelStyle);
    }

    return Tooltip(
      message: localizations.questionNavigationOpen,
      child: InkWell(
        key: const ValueKey('question-navigation-open-button'),
        borderRadius: BorderRadius.circular(AppLayout.pillRadius),
        onTap: onOpenQuestionNavigator,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: labelStyle),
              const SizedBox(width: 6),
              Icon(
                Icons.view_list,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
