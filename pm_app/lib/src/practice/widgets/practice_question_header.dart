import 'package:flutter/material.dart';
import 'package:pm_questions/pm_questions.dart';

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

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        Text(
          question.code,
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
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

    return Semantics(
      button: true,
      label: '$label. ${localizations.questionNavigationOpen}',
      excludeSemantics: true,
      onTap: onOpenQuestionNavigator,
      child: Tooltip(
        message: localizations.questionNavigationOpen,
        child: InkWell(
          key: const ValueKey('question-navigation-open-button'),
          borderRadius: BorderRadius.circular(AppLayout.pillRadius),
          onTap: onOpenQuestionNavigator,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(label, style: labelStyle),
                Icon(
                  Icons.view_list,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
