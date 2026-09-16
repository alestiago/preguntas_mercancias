import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../l10n/app_localizations.dart';
import '../practice/practice_page.dart';

class AnswerHistoryPage extends StatelessWidget {
  const AnswerHistoryPage({
    super.key,
    required this.questions,
    required this.questionProgressStore,
  });

  final List<Question> questions;
  final QuestionProgressStore questionProgressStore;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.answerHistoryTitle)),
      body: SafeArea(
        child: _AnswerHistoryBody(
          questions: questions,
          questionProgressStore: questionProgressStore,
          onQuestionSelected: (question) =>
              _openQuestionPractice(context, question),
        ),
      ),
    );
  }

  void _openQuestionPractice(BuildContext context, Question question) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => QuestionPracticePage(
          loadQuestions: (_) async => [question],
          questionProgressStore: questionProgressStore,
          initialSection: null,
          isSimulacroMode: true,
        ),
      ),
    );
  }
}

class _AnswerHistoryBody extends StatelessWidget {
  const _AnswerHistoryBody({
    required this.questions,
    required this.questionProgressStore,
    required this.onQuestionSelected,
  });

  final List<Question> questions;
  final QuestionProgressStore questionProgressStore;
  final ValueChanged<Question> onQuestionSelected;

  @override
  Widget build(BuildContext context) {
    final questionsByCode = {
      for (final question in questions) question.code: question,
    };

    return StreamBuilder<List<QuestionAnswerRecord>>(
      stream: questionProgressStore.watchAnswerHistory(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorState(error: snapshot.error!);
        }

        final answers = snapshot.data;
        if (answers == null) {
          return const _LoadingState();
        }

        if (answers.isEmpty) {
          return const _EmptyHistoryState();
        }

        return _AnswerHistoryList(
          sections: _historySectionsFor(answers),
          questionsByCode: questionsByCode,
          onQuestionSelected: onQuestionSelected,
        );
      },
    );
  }
}

class _AnswerHistoryList extends StatelessWidget {
  const _AnswerHistoryList({
    required this.sections,
    required this.questionsByCode,
    required this.onQuestionSelected,
  });

  final List<_AnswerHistorySection> sections;
  final Map<String, Question> questionsByCode;
  final ValueChanged<Question> onQuestionSelected;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        for (final section in sections)
          SliverStickyHeader(
            header: _AnswerHistoryDateHeader(section: section),
            sliver: SliverList.separated(
              itemCount: section.answers.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final answer = section.answers[index];
                final question = questionsByCode[answer.questionCode];
                return _AnswerHistoryTile(
                  answer: answer,
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

class _AnswerHistoryDateHeader extends StatelessWidget {
  const _AnswerHistoryDateHeader({required this.section});

  final _AnswerHistorySection section;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final formattedDate = section.formattedDate(context);

    return DecoratedBox(
      key: ValueKey('answer-history-date-header-$formattedDate'),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(
                formattedDate,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Text(
                    '${section.answers.length}',
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
        _selectedAnswerText ?? answer.selectedOption.code;

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
              '${answer.questionCode} · ${_formatAnsweredTime(context, answer.answeredAt)}',
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

  String? get _selectedAnswerText {
    final question = this.question;
    if (question == null) {
      return null;
    }

    for (final possibleAnswer in question.answers) {
      if (possibleAnswer.option == answer.selectedOption) {
        return possibleAnswer.text;
      }
    }

    return null;
  }

  String _formatAnsweredTime(BuildContext context, DateTime answeredAt) {
    final locale = Localizations.localeOf(context).toString();
    return intl.DateFormat('HH:mm', locale).format(answeredAt);
  }
}

List<_AnswerHistorySection> _historySectionsFor(
  List<QuestionAnswerRecord> answers,
) {
  final groupedAnswers = <DateTime, List<QuestionAnswerRecord>>{};
  for (final answer in answers) {
    final answeredAt = answer.answeredAt;
    final date = DateTime(answeredAt.year, answeredAt.month, answeredAt.day);
    groupedAnswers.putIfAbsent(date, () => []).add(answer);
  }

  return [
    for (final entry in groupedAnswers.entries)
      _AnswerHistorySection(
        date: entry.key,
        answers: List.unmodifiable(entry.value),
      ),
  ];
}

final class _AnswerHistorySection {
  const _AnswerHistorySection({required this.date, required this.answers});

  final DateTime date;
  final List<QuestionAnswerRecord> answers;

  String formattedDate(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return intl.DateFormat('EEE d MMM y', locale).format(date);
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(dimension: 36, child: CircularProgressIndicator()),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 42, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(
              localizations.answerHistoryEmpty,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('$error', textAlign: TextAlign.center),
      ),
    );
  }
}
