import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../l10n/app_localizations.dart';
import '../history/answer_history_page.dart';
import '../practice/bloc/practice_bloc.dart';
import '../practice/practice_page.dart';
import '../practice/practice_session_config.dart';
import '../questions/draw_simulacro_questions.dart';
import '../questions/load_questions.dart';
import '../settings/bloc/settings_bloc.dart';
import '../settings/settings_page.dart';
import 'bloc/home_bloc.dart';

class QuestionHomePage extends StatelessWidget {
  const QuestionHomePage({
    super.key,
    LoadQuestions? loadQuestions,
    this.questionProgressStore,
  }) : loadQuestions = loadQuestions ?? loadQuestionsFromBank;

  final LoadQuestions loadQuestions;
  final QuestionProgressStore? questionProgressStore;

  @override
  Widget build(BuildContext context) {
    final progressStore =
        questionProgressStore ?? context.read<QuestionProgressStore>();

    return BlocProvider(
      create: (_) => HomeBloc(
        loadQuestions: loadQuestions,
        questionProgressStore: progressStore,
      )..add(const HomeStarted()),
      child: _QuestionHomeView(
        loadQuestions: loadQuestions,
        questionProgressStore: progressStore,
      ),
    );
  }
}

class _QuestionHomeView extends StatelessWidget {
  const _QuestionHomeView({
    required this.loadQuestions,
    required this.questionProgressStore,
  });

  final LoadQuestions loadQuestions;
  final QuestionProgressStore questionProgressStore;

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
              HomeLoading() => const _LoadingState(),
              HomeLoadFailure(:final error) => _ErrorState(
                error: error,
                onRetry: () {
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
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            SettingsPage(questionProgressStore: questionProgressStore),
      ),
    );
  }

  void _openPractice(
    BuildContext context, {
    LoadQuestions? practiceLoadQuestions,
    LoadMoreQuestions? loadMoreQuestions,
    required PracticeSessionConfig session,
  }) {
    final homeBloc = context.read<HomeBloc>();

    Navigator.of(context)
        .push<void>(
          MaterialPageRoute(
            builder: (_) => QuestionPracticePage(
              loadQuestions: practiceLoadQuestions ?? loadQuestions,
              loadMoreQuestions: loadMoreQuestions,
              questionProgressStore: questionProgressStore,
              session: session,
            ),
          ),
        )
        .whenComplete(() {
          if (!homeBloc.isClosed) {
            homeBloc.add(const HomeProgressRefreshed());
          }
        });
  }

  void _openAnswerHistory(BuildContext context, HomeLoaded state) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AnswerHistoryPage(
          questions: state.questions,
          questionProgressStore: questionProgressStore,
        ),
      ),
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
      session: PracticeSessionConfig.review(shuffleAnswers: shuffleAnswers),
    );
  }

  void _openPendingPractice(BuildContext context, HomeLoaded state) {
    final shuffleAnswers = context
        .read<SettingsBloc>()
        .state
        .answerShuffleEnabled;
    final session = PracticeSessionConfig.pending(
      shuffleAnswers: shuffleAnswers,
      pendingQuestionCount: state.unansweredQuestionCount,
      pendingQuestionCountsBySection: state.pendingQuestionCountsBySection,
    );

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
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          children: [
            Text(
              localizations.homeProgressTitle,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
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
        ),
      ),
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

    if (_total == 0) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const SizedBox(height: 18),
      );
    }

    return ClipRRect(
      key: const ValueKey('home-progress-bar'),
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 18,
        child: Row(
          children: [
            if (correctCount > 0)
              Expanded(
                flex: correctCount,
                child: const ColoredBox(color: Color(0xFF2E7D32)),
              ),
            if (incorrectCount > 0)
              Expanded(
                flex: incorrectCount,
                child: const ColoredBox(color: Color(0xFFC62828)),
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
          color: const Color(0xFF2E7D32),
        ),
        _ProgressStat(
          key: const ValueKey('home-incorrect-stat'),
          countKey: const ValueKey('home-incorrect-count'),
          icon: Icons.error,
          label: localizations.questionsToReview,
          count: state.incorrectQuestionCount,
          color: const Color(0xFFC62828),
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
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
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
                            fontWeight: FontWeight.w800,
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(dimension: 36, child: CircularProgressIndicator()),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 42,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 14),
            Text(
              localizations.homeLoadFailure,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(localizations.retry),
            ),
          ],
        ),
      ),
    );
  }
}

extension _HomeLoadedPracticeSources on HomeLoaded {
  LoadQuestions reviewLoadQuestions() {
    final reviewQuestionCodes = <String>{};

    for (final questionCode in questionCodes) {
      final progress = progressSnapshot.progressFor(questionCode);
      if (progress != null && progress.correctAttempts == 0) {
        reviewQuestionCodes.add(questionCode);
      }
    }

    return questions.filteredLoadQuestions(reviewQuestionCodes);
  }

  Map<String, int> get pendingQuestionCountsBySection {
    final countsBySection = <String, int>{};

    for (final question in questions) {
      if (progressSnapshot.progressFor(question.code) != null) {
        continue;
      }

      countsBySection.update(
        question.section,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    return Map.unmodifiable(countsBySection);
  }

  LoadQuestions pendingLoadQuestions({required int batchSize}) {
    return (section) async => questions.pendingQuestionBatch(
      progressSnapshot: progressSnapshot,
      section: section,
      loadedQuestionCodes: const <String>{},
      batchSize: batchSize,
    );
  }

  LoadMoreQuestions pendingLoadMoreQuestions({required int batchSize}) {
    return (section, loadedQuestionCodes, progressSnapshot) async {
      return questions.pendingQuestionBatch(
        progressSnapshot: progressSnapshot,
        section: section,
        loadedQuestionCodes: loadedQuestionCodes,
        batchSize: batchSize,
      );
    };
  }
}

extension _QuestionListPracticeFilters on List<Question> {
  LoadQuestions filteredLoadQuestions(Set<String> questionCodes) {
    final filteredQuestions = List<Question>.unmodifiable(
      where((question) => questionCodes.contains(question.code)),
    );

    return (section) async {
      if (section == null) {
        return filteredQuestions;
      }

      return List<Question>.unmodifiable(
        filteredQuestions.where((question) => question.section == section),
      );
    };
  }

  List<Question> pendingQuestionBatch({
    required QuestionProgressSnapshot progressSnapshot,
    required String? section,
    required Set<String> loadedQuestionCodes,
    required int batchSize,
  }) {
    return List<Question>.unmodifiable(
      where(
        (question) =>
            (section == null || question.section == section) &&
            !loadedQuestionCodes.contains(question.code) &&
            progressSnapshot.progressFor(question.code) == null,
      ).take(batchSize),
    );
  }
}
