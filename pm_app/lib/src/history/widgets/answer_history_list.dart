import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../../l10n/app_localizations.dart';
import '../bloc/answer_history_bloc.dart';
import 'answer_history_date_header.dart';

class AnswerHistoryList extends StatelessWidget {
  const AnswerHistoryList({
    super.key,
    required this.sections,
    required this.onQuestionSelected,
  });

  final List<AnswerHistorySection> sections;
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
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    final selectedAnswerText =
        question?.answerForOrNull(answer.selectedOption)?.text ??
        answer.selectedOption.code;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        child: Icon(answer.isCorrect ? Icons.check : Icons.close),
      ),
      title: Text(
        question?.prompt ?? localizations.answerHistoryUnknownQuestion,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${answer.questionCode} · ${_formatHistoryTime(context, answer.answeredAt)}',
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

String _formatHistoryTime(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toString();
  return intl.DateFormat('HH:mm', locale).format(date);
}
