import 'package:flutter/material.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../l10n/app_localizations.dart';
import '../navigation/app_navigator.dart';

enum PracticeSummaryReturnDestination { home, answerHistory }

class PracticeSummaryPage extends StatelessWidget {
  const PracticeSummaryPage({
    super.key,
    required this.summary,
    required this.returnDestination,
  });

  final PracticeSummary summary;
  final PracticeSummaryReturnDestination returnDestination;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.practiceSummaryTitle)),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _SummaryHeader(summary: summary)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  localizations.practiceSummaryQuestionsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SliverList.separated(
              itemCount: summary.questions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final question = summary.questions[index];
                return _SummaryQuestionTile(
                  question: question,
                  selectedOption: summary.selectedOptionFor(question),
                );
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton(
                  key: ValueKey(returnDestination.buttonKey),
                  onPressed: () => AppNavigator.pop(context),
                  child: Text(returnDestination.label(localizations)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.summary});

  final PracticeSummary summary;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final scorePercentage = (summary.scoreRatio * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        children: [
          Icon(
            summary.scoreRatio >= 0.5 ? Icons.emoji_events : Icons.flag,
            size: 48,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            localizations.scorePill(
              summary.correctQuestionCount,
              summary.totalQuestionCount,
              scorePercentage,
            ),
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.practiceSummaryElapsedTime(
              summary.elapsedTime.timerLabel,
            ),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryQuestionTile extends StatelessWidget {
  const _SummaryQuestionTile({
    required this.question,
    required this.selectedOption,
  });

  final Question question;
  final QuestionOption? selectedOption;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final selectedOption = this.selectedOption;
    final isCorrect =
        selectedOption != null && question.isCorrect(selectedOption);
    final isUnanswered = selectedOption == null;
    final color = isUnanswered
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : isCorrect
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);

    return ListTile(
      key: ValueKey('summary-question-${question.code}'),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        child: Icon(
          isUnanswered
              ? Icons.horizontal_rule
              : isCorrect
              ? Icons.check
              : Icons.close,
        ),
      ),
      title: Text(
        question.prompt,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: isUnanswered
          ? Text(
              '${question.code} · ${localizations.practiceSummaryUnanswered}',
            )
          : Text(question.code),
    );
  }
}

extension on PracticeSummaryReturnDestination {
  String get buttonKey => switch (this) {
    PracticeSummaryReturnDestination.home => 'back-to-home-button',
    PracticeSummaryReturnDestination.answerHistory =>
      'back-to-answer-history-button',
  };

  String label(AppLocalizations localizations) => switch (this) {
    PracticeSummaryReturnDestination.home => localizations.backToHome,
    PracticeSummaryReturnDestination.answerHistory =>
      localizations.backToAnswerHistory,
  };
}

extension _SummaryDurationFormatting on Duration {
  String get timerLabel {
    final hours = inHours;
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }
}
