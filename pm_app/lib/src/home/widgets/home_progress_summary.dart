import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/theme/app_theme.dart';
import '../../questions/draw_simulacro_questions.dart';
import '../bloc/home_bloc.dart';

class HomeProgressSummary extends StatelessWidget {
  const HomeProgressSummary({
    super.key,
    required this.state,
    required this.onStartSimulacroPractice,
    required this.onStartReviewPractice,
    required this.onStartPendingPractice,
  });

  final HomeLoaded state;
  final VoidCallback onStartSimulacroPractice;
  final VoidCallback onStartReviewPractice;
  final VoidCallback onStartPendingPractice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressSummaryBar(
          correctCount: state.correctQuestionCount,
          incorrectCount: state.incorrectQuestionCount,
          unansweredCount: state.unansweredQuestionCount,
        ),
        const SizedBox(height: 18),
        _ProgressStats(
          state: state,
          onStartSimulacroPractice: onStartSimulacroPractice,
          onStartReviewPractice: onStartReviewPractice,
          onStartPendingPractice: onStartPendingPractice,
        ),
      ],
    );
  }
}

class _ProgressSummaryBar extends StatelessWidget {
  const _ProgressSummaryBar({
    required this.correctCount,
    required this.incorrectCount,
    required this.unansweredCount,
  });

  final int correctCount;
  final int incorrectCount;
  final int unansweredCount;

  int get _total => correctCount + incorrectCount + unansweredCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resultColors = AppResultColors.of(context);

    if (_total == 0) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppLayout.pillRadius),
        ),
        child: const SizedBox(height: 18),
      );
    }

    return ClipRRect(
      key: const ValueKey('home-progress-bar'),
      borderRadius: BorderRadius.circular(AppLayout.pillRadius),
      child: SizedBox(
        height: 18,
        child: Row(
          children: [
            if (correctCount > 0)
              Expanded(
                flex: correctCount,
                child: ColoredBox(color: resultColors.correct),
              ),
            if (incorrectCount > 0)
              Expanded(
                flex: incorrectCount,
                child: ColoredBox(color: colorScheme.error),
              ),
            if (unansweredCount > 0)
              Expanded(
                flex: unansweredCount,
                child: ColoredBox(color: colorScheme.surfaceContainerHighest),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStats extends StatelessWidget {
  const _ProgressStats({
    required this.state,
    required this.onStartSimulacroPractice,
    required this.onStartReviewPractice,
    required this.onStartPendingPractice,
  });

  final HomeLoaded state;
  final VoidCallback onStartSimulacroPractice;
  final VoidCallback onStartReviewPractice;
  final VoidCallback onStartPendingPractice;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final resultColors = AppResultColors.of(context);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _ProgressStat(
          key: const ValueKey('home-correct-stat'),
          countKey: const ValueKey('home-correct-count'),
          icon: Icons.check_circle,
          label: localizations.correctQuestions,
          count: state.correctQuestionCount,
          color: resultColors.correct,
        ),
        _ProgressStat(
          key: const ValueKey('home-incorrect-stat'),
          countKey: const ValueKey('home-incorrect-count'),
          icon: Icons.error,
          label: localizations.questionsToReview,
          count: state.incorrectQuestionCount,
          color: Theme.of(context).colorScheme.error,
          onTap: state.incorrectQuestionCount > 0
              ? onStartReviewPractice
              : null,
        ),
        _ProgressStat(
          key: const ValueKey('home-unanswered-stat'),
          countKey: const ValueKey('home-unanswered-count'),
          icon: Icons.radio_button_unchecked,
          label: localizations.pendingQuestions,
          count: state.unansweredQuestionCount,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          onTap: state.unansweredQuestionCount > 0
              ? onStartPendingPractice
              : null,
        ),
        _ProgressStat(
          key: const ValueKey('start-simulacro-button'),
          countKey: const ValueKey('home-simulacro-count'),
          icon: Icons.quiz,
          label: localizations.startSimulacro,
          count: simulacroQuestionCount,
          color: Theme.of(context).colorScheme.primary,
          onTap: onStartSimulacroPractice,
        ),
      ],
    );
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({
    super.key,
    required this.countKey,
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    this.onTap,
  });

  final Key countKey;
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: onTap != null,
      enabled: onTap != null,
      child: Material(
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppLayout.cardRadius),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppLayout.cardRadius),
          child: SizedBox(
            width: 170,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count',
                          key: countKey,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: AppTypography.strongWeight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
