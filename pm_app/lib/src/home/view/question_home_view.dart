import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_loading_indicator.dart';
import '../../app/widgets/app_message_panel.dart';
import '../../history/answer_history_page.dart';
import '../../navigation/app_navigator.dart';
import '../../practice/practice_page.dart';
import '../../practice/practice_session_config.dart';
import '../../questions/draw_simulacro_questions.dart';
import '../../questions/load_questions.dart';
import '../../settings/bloc/settings_bloc.dart';
import '../../settings/settings_page.dart';
import '../bloc/home_bloc.dart';
import '../widgets/home_progress_summary.dart';

class QuestionHomeView extends StatelessWidget {
  const QuestionHomeView({super.key, required this.loadQuestions});

  final LoadQuestions loadQuestions;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final localizations = AppLocalizations.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.appTitle),
            actions: [
              if (state case HomeLoaded loadedState)
                IconButton(
                  key: const ValueKey('answer-history-button'),
                  tooltip: localizations.answerHistoryTitle,
                  onPressed: () => _openAnswerHistory(context, loadedState),
                  icon: const Icon(Icons.history),
                ),
              if (state is HomeLoaded)
                IconButton(
                  key: const ValueKey('settings-button'),
                  tooltip: localizations.settingsTitle,
                  onPressed: () => _openSettings(context),
                  icon: const Icon(Icons.settings),
                ),
            ],
          ),
          body: SafeArea(
            child: switch (state) {
              HomeLoading() => const AppLoadingIndicator(),
              HomeLoadFailure() => AppMessagePanel(
                icon: Icons.error_outline,
                iconColor: Theme.of(context).colorScheme.error,
                message: localizations.homeLoadFailure,
                actionLabel: localizations.retry,
                onAction: () {
                  context.read<HomeBloc>().add(const HomeRetried());
                },
              ),
              HomeLoaded loadedState => _HomeContent(
                state: loadedState,
                onStartSimulacroPractice: () =>
                    _openSimulacroPractice(context, loadedState),
                onStartReviewPractice: () =>
                    _openReviewPractice(context, loadedState),
                onStartPendingPractice: () =>
                    _openPendingPractice(context, loadedState),
              ),
            },
          ),
        );
      },
    );
  }

  void _openSettings(BuildContext context) {
    AppNavigator.push<void>(context, const SettingsPage());
  }

  void _openPractice(
    BuildContext context, {
    LoadQuestions? practiceLoadQuestions,
    LoadMoreQuestions? loadMoreQuestions,
    required PracticeSessionConfig session,
  }) {
    AppNavigator.push<void>(
      context,
      QuestionPracticePage(
        loadQuestions: practiceLoadQuestions ?? loadQuestions,
        loadMoreQuestions: loadMoreQuestions,
        session: session,
      ),
    );
  }

  void _openAnswerHistory(BuildContext context, HomeLoaded state) {
    AppNavigator.push<void>(
      context,
      AnswerHistoryPage(questions: state.questions),
    );
  }

  void _openSimulacroPractice(BuildContext context, HomeLoaded state) {
    final simulacroQuestions = drawSimulacroQuestions(state.questions);
    final shuffleAnswers = context
        .read<SettingsBloc>()
        .state
        .answerShuffleEnabled;

    _openPractice(
      context,
      practiceLoadQuestions: (_) async => simulacroQuestions,
      session: PracticeSessionConfig.simulacro(shuffleAnswers: shuffleAnswers),
    );
  }

  void _openReviewPractice(BuildContext context, HomeLoaded state) {
    final shuffleAnswers = context
        .read<SettingsBloc>()
        .state
        .answerShuffleEnabled;

    _openPractice(
      context,
      practiceLoadQuestions: state.reviewLoadQuestions(),
      session: state.reviewSession(shuffleAnswers: shuffleAnswers),
    );
  }

  void _openPendingPractice(BuildContext context, HomeLoaded state) {
    final shuffleAnswers = context
        .read<SettingsBloc>()
        .state
        .answerShuffleEnabled;
    final session = state.pendingSession(shuffleAnswers: shuffleAnswers);

    _openPractice(
      context,
      practiceLoadQuestions: state.pendingLoadQuestions(
        batchSize: session.pendingBatchSize,
      ),
      loadMoreQuestions: state.pendingLoadMoreQuestions(
        batchSize: session.pendingBatchSize,
      ),
      session: session,
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppLayout.pageHorizontalInset,
            24,
            AppLayout.pageHorizontalInset,
            28,
          ),
          children: [
            Text(
              localizations.homeProgressTitle,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: AppTypography.strongWeight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.questionsInBank(state.totalQuestionCount),
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),
            HomeProgressSummary(
              state: state,
              onStartSimulacroPractice: onStartSimulacroPractice,
              onStartReviewPractice: onStartReviewPractice,
              onStartPendingPractice: onStartPendingPractice,
            ),
          ],
        ),
      ),
    );
  }
}
