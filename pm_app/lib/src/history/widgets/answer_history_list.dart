import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/theme/app_theme.dart';
import '../bloc/answer_history_bloc.dart';
import '../history_date_time_format.dart';
import 'answer_history_date_header.dart';

class AnswerHistoryList extends StatelessWidget {
  const AnswerHistoryList({
    super.key,
    required this.sections,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onQuestionSelected,
  });

  final List<AnswerHistorySection> sections;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final ValueChanged<Question> onQuestionSelected;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        for (final section in sections)
          SliverStickyHeader(
            header: AnswerHistoryDateHeader(section: section),
            sliver: SliverList.separated(
              itemCount: section.entries.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = section.entries[index];
                final question = entry.question;
                return _AnswerHistoryTile(
                  answer: entry.answer,
                  question: question,
                  onTap: question == null
                      ? null
                      : () => onQuestionSelected(question),
                );
              },
            ),
          ),
        if (hasMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: isLoadingMore
                    ? const CircularProgressIndicator()
                    : FilledButton.tonal(
                        key: const ValueKey('answer-history-load-more'),
                        onPressed: onLoadMore,
                        child: Text(
                          AppLocalizations.of(context).answerHistoryLoadMore,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AnswerHistoryTile extends StatelessWidget {
  const _AnswerHistoryTile({
    required this.answer,
    required this.question,
    required this.onTap,
  });

  final QuestionAnswerRecord answer;
  final Question? question;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final color = answer.isCorrect
        ? AppResultColors.of(context).correct
        : Theme.of(context).colorScheme.error;
    final selectedAnswerText =
        question?.answerForOrNull(answer.selectedOption)?.text ??
        answer.selectedOption.code;

    return ListTile(
      onTap: onTap,
      leading: Semantics(
        container: true,
        label: answer.isCorrect
            ? localizations.correctAnswerFeedbackTitle
            : localizations.incorrectAnswerFeedbackTitle,
        child: ExcludeSemantics(
          child: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(answer.isCorrect ? Icons.check : Icons.close),
          ),
        ),
      ),
      title: Text(
        question?.prompt ?? localizations.answerHistoryUnknownQuestion,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: AppTypography.emphasizedWeight),
      ),
      subtitle: Padding(
        padding: const EdgeInsetsDirectional.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${answer.questionCode} · ${HistoryDateTimeFormat.time(context, answer.answeredAt)}',
            ),
            Text(
              localizations.answerHistorySelection(selectedAnswerText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
    );
  }
}
