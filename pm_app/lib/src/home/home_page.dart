import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../l10n/app_localizations.dart';
import '../practice/practice_page.dart';
import '../questions/load_questions.dart';
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
          appBar: AppBar(title: Text(localizations.appTitle)),
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
                onStartPractice: () => _openPractice(context),
                onStartReviewPractice: () =>
                    _openReviewPractice(context, loadedState),
              ),
            },
          ),
        );
      },
    );
  }

  void _openPractice(
    BuildContext context, {
    LoadQuestions? practiceLoadQuestions,
    String? initialSection = '1A',
    bool isReviewMode = false,
  }) {
    final homeBloc = context.read<HomeBloc>();

    Navigator.of(context)
        .push<void>(
          MaterialPageRoute(
            builder: (_) => QuestionPracticePage(
              loadQuestions: practiceLoadQuestions ?? loadQuestions,
              questionProgressStore: questionProgressStore,
              initialSection: initialSection,
              isReviewMode: isReviewMode,
            ),
          ),
        )
        .whenComplete(() {
          if (!homeBloc.isClosed) {
            homeBloc.add(const HomeProgressRefreshed());
          }
        });
  }

  void _openReviewPractice(BuildContext context, HomeLoaded state) {
    _openPractice(
      context,
      practiceLoadQuestions: _reviewLoadQuestionsFor(state),
      initialSection: null,
      isReviewMode: true,
    );
  }

  LoadQuestions _reviewLoadQuestionsFor(HomeLoaded state) {
    final reviewQuestionCodes = <String>{};
    final reviewSections = <String>{};

    for (final questionCode in state.questionCodes) {
      final progress = state.progressSnapshot.progressFor(questionCode);
      if (progress != null && progress.correctAttempts == 0) {
        reviewQuestionCodes.add(questionCode);
        reviewSections.add(progress.section);
      }
    }

    final orderedReviewSections = [
      for (final section in QuestionBankLoader.sections)
        if (reviewSections.contains(section)) section,
      for (final section in reviewSections)
        if (!QuestionBankLoader.sections.contains(section)) section,
    ];

    return (section) async {
      if (reviewQuestionCodes.isEmpty) {
        return const <Question>[];
      }

      if (section != null && !reviewSections.contains(section)) {
        return const <Question>[];
      }

      final sections = section == null ? orderedReviewSections : [section];
      final questions = <Question>[];

      for (final section in sections) {
        questions.addAll(await loadQuestions(section));
      }

      return List<Question>.unmodifiable(
        questions.where(
          (question) => reviewQuestionCodes.contains(question.code),
        ),
      );
    };
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.state,
    required this.onStartPractice,
    required this.onStartReviewPractice,
  });

  final HomeLoaded state;
  final VoidCallback onStartPractice;
  final VoidCallback onStartReviewPractice;

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
              onStartReviewPractice: onStartReviewPractice,
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: const ValueKey('start-practice-button'),
                onPressed: onStartPractice,
                icon: const Icon(Icons.play_arrow),
                label: Text(localizations.startPractice),
              ),
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
    required this.onStartReviewPractice,
  });

  final HomeLoaded state;
  final VoidCallback onStartReviewPractice;

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
