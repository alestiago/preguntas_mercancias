import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../../l10n/app_localizations.dart';
import '../../navigation/app_navigator.dart';
import '../../practice/practice_page.dart';
import '../../practice/practice_session_config.dart';
import '../../settings/bloc/settings_bloc.dart';
import '../bloc/answer_history_bloc.dart';
import '../widgets/answer_history_list.dart';

class AnswerHistoryView extends StatelessWidget {
  const AnswerHistoryView({super.key});

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
            AnswerHistoryLoaded(:final sections) => AnswerHistoryList(
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
