import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/widgets/app_loading_indicator.dart';
import '../../app/widgets/app_message_panel.dart';
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
            AnswerHistoryLoading() => const AppLoadingIndicator(),
            AnswerHistoryFailure() => AppMessagePanel(
              icon: Icons.error_outline,
              iconColor: Theme.of(context).colorScheme.error,
              message: localizations.answerHistoryLoadFailure,
              actionLabel: localizations.retry,
              onAction: () => context.read<AnswerHistoryBloc>().add(
                const AnswerHistoryRetried(),
              ),
            ),
            AnswerHistoryEmpty() => AppMessagePanel(
              icon: Icons.history,
              message: localizations.answerHistoryEmpty,
            ),
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
