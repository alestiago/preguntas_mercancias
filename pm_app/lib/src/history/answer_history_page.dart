import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../l10n/app_localizations.dart';
import '../navigation/app_navigator.dart';
import '../practice/practice_page.dart';
import '../practice/practice_session_config.dart';
import '../settings/bloc/settings_bloc.dart';
import 'bloc/answer_history_bloc.dart';

class AnswerHistoryPage extends StatelessWidget {
  const AnswerHistoryPage({super.key, required this.questions});

  final List<Question> questions;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AnswerHistoryBloc(
        questionProgressStore: context.read<QuestionProgressStore>(),
        questions: questions,
      ),
      child: const _AnswerHistoryView(),
    );
  }
}

class _AnswerHistoryView extends StatelessWidget {
  const _AnswerHistoryView();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.answerHistoryTitle)),
      body: SafeArea(
        child: BlocBuilder<AnswerHistoryBloc, AnswerHistoryState>(
          builder: (context, state) => switch (state) {
            AnswerHistoryLoading() => const _LoadingState(),
            AnswerHistoryFailure(:final error) => _ErrorState(error: error),
            AnswerHistoryEmpty() => const _EmptyHistoryState(),
            AnswerHistoryLoaded(:final sections) => _AnswerHistoryList(
              sections: sections,
              onQuestionSelected: (question) =>
                  _openQuestionPractice(context, question),
            ),
          },
        ),
      ),
    );
  }

  void _openQuestionPractice(BuildContext context, Question question) {
    final shuffleAnswers = context
        .read<SettingsBloc>()
        .state
        .answerShuffleEnabled;

    AppNavigator.push<void>(
      context,
      QuestionPracticePage(
        loadQuestions: (_) async => [question],
        session: PracticeSessionConfig.singleQuestion(
          shuffleAnswers: shuffleAnswers,
        ),
      ),
    );
  }
}

class _AnswerHistoryList extends StatelessWidget {
  const _AnswerHistoryList({
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
            header: _AnswerHistoryDateHeader(section: section),
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

class _AnswerHistoryDateHeader extends StatelessWidget {
  const _AnswerHistoryDateHeader({required this.section});

  final AnswerHistorySection section;

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
                    '${section.entries.length}',
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
              '${answer.questionCode} · ${answer.answeredAt.historyTime(context)}',
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

extension _AnswerHistoryDateFormatting on DateTime {
  String historyTime(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return intl.DateFormat('HH:mm', locale).format(this);
  }

  String historyDate(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return intl.DateFormat('EEE d MMM y', locale).format(this);
  }
}

extension on AnswerHistorySection {
  String formattedDate(BuildContext context) {
    return date.historyDate(context);
  }
}
