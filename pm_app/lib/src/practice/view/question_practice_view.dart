import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_loading_indicator.dart';
import '../../app/widgets/app_message_panel.dart';
import '../../navigation/app_navigator.dart';
import '../../practice_summary/practice_summary_page.dart';
import '../bloc/practice_bloc.dart';
import '../practice_question_policy.dart';
import '../practice_session_clock.dart';
import '../practice_session_config.dart';
import '../widgets/answer_feedback.dart';
import '../widgets/exit_practice_button.dart';
import '../widgets/practice_page_app_bar.dart';
import '../widgets/practice_progress_divider.dart';
import '../widgets/practice_question_header.dart';
import '../widgets/practice_question_panel.dart';
import '../widgets/practice_section_selector.dart';
import '../widgets/practice_session_footer.dart';
import '../widgets/question_navigation_drawer.dart';

class QuestionPracticeView extends StatefulWidget {
  const QuestionPracticeView({super.key, required this.sessionClock});

  final PracticeSessionClock sessionClock;

  @override
  State<QuestionPracticeView> createState() => _QuestionPracticeViewState();
}

class _QuestionPracticeViewState extends State<QuestionPracticeView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  var _exitApproved = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PracticeBloc, PracticeState>(
      builder: (context, state) {
        final footerState =
            state is PracticeLoaded && state.questions.isNotEmpty
            ? state
            : null;

        return PopScope(
          canPop: _exitApproved || state.exitPolicy == PracticeExitPolicy.allow,
          onPopInvokedWithResult: (didPop, _) async {
            if (!didPop) {
              await _requestExit(context, state);
            }
          },
          child: Scaffold(
            key: _scaffoldKey,
            endDrawerEnableOpenDragGesture:
                state.isQuestionDrawerNavigationEnabled,
            endDrawer:
                state is PracticeLoaded &&
                    state.isQuestionDrawerNavigationEnabled
                ? QuestionNavigationDrawer(
                    state: state,
                    onQuestionSelected: (index) {
                      Navigator.of(context).pop();
                      context.read<PracticeBloc>().add(
                        QuestionNavigationPressed(index),
                      );
                    },
                  )
                : null,
            appBar: PracticePageAppBar(
              state: state,
              sessionClock: widget.sessionClock,
              onExitRequested: () => _requestExit(context, state),
              onOpenQuestionNavigator: _openQuestionNavigator,
            ),
            bottomNavigationBar: footerState == null
                ? null
                : _PracticeSessionFooterBar(
                    child: PracticeSessionFooter(
                      primaryAction: footerState.primaryAction,
                      isPrimaryActionEnabled:
                          footerState.isPrimaryActionEnabled,
                      isPreviousActionEnabled:
                          footerState.isPreviousActionEnabled,
                      onPrimaryAction: () =>
                          _performPrimaryAction(context, footerState),
                      onPreviousQuestion: () => context
                          .read<PracticeBloc>()
                          .add(const PreviousQuestionPressed()),
                    ),
                  ),
            body: SafeArea(
              child: Column(
                children: [
                  if (state is PracticeLoaded && state.questions.isNotEmpty)
                    PracticeProgressDivider(
                      segments: state.progressSegments,
                      currentIndex: state.currentIndex,
                    ),
                  Expanded(
                    child: _PracticeBody(
                      state: state,
                      onOpenQuestionNavigator:
                          state.isQuestionDrawerNavigationEnabled
                          ? _openQuestionNavigator
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _requestExit(BuildContext context, PracticeState state) async {
    switch (state.exitPolicy) {
      case PracticeExitPolicy.blocked:
        return;
      case PracticeExitPolicy.confirm:
        final shouldExit = await showExitPracticeConfirmationDialog(context);
        if (!shouldExit || !context.mounted) {
          return;
        }
        setState(() => _exitApproved = true);
        await WidgetsBinding.instance.endOfFrame;
        if (context.mounted) {
          AppNavigator.pop(context);
        }
        return;
      case PracticeExitPolicy.allow:
        AppNavigator.pop(context);
        return;
    }
  }

  void _performPrimaryAction(BuildContext context, PracticeLoaded state) {
    switch (state.primaryAction) {
      case PracticePrimaryAction.finish:
        if (state.mode == PracticeMode.simulacro) {
          _finishSimulacro(context, state);
        } else {
          AppNavigator.pop(context);
        }
        return;
      case PracticePrimaryAction.next || PracticePrimaryAction.restart:
        context.read<PracticeBloc>().add(const NextQuestionPressed());
        return;
    }
  }

  void _finishSimulacro(BuildContext context, PracticeLoaded state) {
    final summary = PracticeSummary(
      questions: state.questions,
      selectedOptionsByQuestionCode: state.selectedOptionsByQuestionCode,
      correctAttemptCount: state.correctAttemptCount,
      incorrectAttemptCount: state.incorrectAttemptCount,
      elapsedTime: widget.sessionClock.elapsed,
    );

    AppNavigator.replace<void, void>(
      context,
      PracticeSummaryPage(
        summary: summary,
        returnDestination: PracticeSummaryReturnDestination.home,
      ),
    );
  }

  void _openQuestionNavigator() {
    _scaffoldKey.currentState?.openEndDrawer();
  }
}

class _PracticeBody extends StatelessWidget {
  const _PracticeBody({
    required this.state,
    required this.onOpenQuestionNavigator,
  });

  final PracticeState state;
  final VoidCallback? onOpenQuestionNavigator;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      PracticeLoading() => const AppLoadingIndicator(),
      PracticeLoadFailure() => AppMessagePanel(
        icon: Icons.error_outline,
        iconColor: Theme.of(context).colorScheme.error,
        message: AppLocalizations.of(context).practiceLoadFailure,
        actionLabel: AppLocalizations.of(context).retry,
        onAction: () => context.read<PracticeBloc>().add(const RetryPressed()),
      ),
      PracticeLoaded(
        questions: final questions,
        pendingBatchState: PendingBatchLoading(),
      )
          when questions.isEmpty =>
        const AppLoadingIndicator(),
      PracticeLoaded(
        questions: final questions,
        pendingBatchState: PendingBatchFailure(),
      )
          when questions.isEmpty =>
        AppMessagePanel(
          icon: Icons.error_outline,
          iconColor: Theme.of(context).colorScheme.error,
          message: AppLocalizations.of(context).practiceLoadFailure,
          actionLabel: AppLocalizations.of(context).retry,
          onAction: () =>
              context.read<PracticeBloc>().add(const PendingBatchRetried()),
        ),
      PracticeLoaded(questions: final questions) when questions.isEmpty =>
        _EmptyState(
          selectedSection: state.selectedSection,
          showSectionSelector:
              state.mode != PracticeMode.simulacro &&
              state.mode != PracticeMode.singleQuestion,
          onSectionSelected: (section) =>
              context.read<PracticeBloc>().add(SectionSelected(section)),
        ),
      PracticeLoaded loadedState => _PracticeContent(
        state: loadedState,
        onOpenQuestionNavigator: onOpenQuestionNavigator,
      ),
    };
  }
}

class _PracticeContent extends StatelessWidget {
  const _PracticeContent({
    required this.state,
    required this.onOpenQuestionNavigator,
  });

  final PracticeLoaded state;
  final VoidCallback? onOpenQuestionNavigator;

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;

    return CustomScrollView(
      slivers: [
        if (state.mode != PracticeMode.simulacro &&
            state.mode != PracticeMode.singleQuestion)
          SliverToBoxAdapter(
            child: PracticeSectionSelector(
              selectedSection: state.selectedSection,
              onSectionSelected: (section) =>
                  context.read<PracticeBloc>().add(SectionSelected(section)),
            ),
          ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: _PracticeContentLayout(
            state: state,
            question: question,
            onAnswer: (option) =>
                context.read<PracticeBloc>().add(AnswerPressed(option)),
            onOpenQuestionNavigator: onOpenQuestionNavigator,
          ),
        ),
      ],
    );
  }
}

class _PracticeContentLayout extends StatelessWidget {
  const _PracticeContentLayout({
    required this.state,
    required this.question,
    required this.onAnswer,
    required this.onOpenQuestionNavigator,
  });

  final PracticeLoaded state;
  final Question question;
  final ValueChanged<QuestionOption> onAnswer;
  final VoidCallback? onOpenQuestionNavigator;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppLayout.pageHorizontalInset,
            8,
            AppLayout.pageHorizontalInset,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PracticeQuestionHeader(
                question: question,
                currentQuestionNumber: state.displayQuestionNumber,
                questionCount: state.displayQuestionCount,
                onOpenQuestionNavigator: onOpenQuestionNavigator,
              ),
              PracticeQuestionPanel(
                question: question,
                answerPresentation: state.currentAnswerPresentation,
                selectedOption: state.selectedOption,
                onAnswer: onAnswer,
              ),
              const SizedBox(height: 16),
              AnswerFeedbackSwitcher(
                answered: state.answered,
                question: question,
                answerPresentation: state.currentAnswerPresentation,
                selectedOption: state.selectedOption,
              ),
              if (state.pendingBatchState case PendingBatchLoading()) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(
                  key: ValueKey('pending-batch-loading'),
                ),
              ],
              if (state.pendingBatchState case PendingBatchFailure()) ...[
                const SizedBox(height: 16),
                _PendingBatchFailurePanel(
                  onRetry: () => context.read<PracticeBloc>().add(
                    const PendingBatchRetried(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeSessionFooterBar extends StatelessWidget {
  const _PracticeSessionFooterBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      key: const ValueKey('practice-session-footer'),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppLayout.pageHorizontalInset,
          12,
          AppLayout.pageHorizontalInset,
          16,
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppLayout.maxContentWidth,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PendingBatchFailurePanel extends StatelessWidget {
  const _PendingBatchFailurePanel({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      key: const ValueKey('pending-batch-failure'),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppLayout.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localizations.practiceLoadFailure,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              key: const ValueKey('pending-batch-retry-button'),
              onPressed: onRetry,
              child: Text(localizations.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.selectedSection,
    required this.showSectionSelector,
    required this.onSectionSelected,
  });

  final String? selectedSection;
  final bool showSectionSelector;
  final ValueChanged<String?> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        if (showSectionSelector)
          PracticeSectionSelector(
            selectedSection: selectedSection,
            onSectionSelected: onSectionSelected,
          ),
        Expanded(
          child: AppMessagePanel(
            icon: Icons.quiz_outlined,
            message: localizations.noQuestionsAvailable,
          ),
        ),
      ],
    );
  }
}

extension _PracticeLoadedPresentation on PracticeLoaded {
  int get displayQuestionNumber => currentIndex + 1;

  int get displayQuestionCount {
    if (mode != PracticeMode.pending) {
      return questions.length;
    }

    final selectedSection = this.selectedSection;
    if (selectedSection != null) {
      return session.pendingQuestionCountsBySection[selectedSection] ??
          questions.length;
    }

    return session.pendingQuestionCount ?? questions.length;
  }

  List<SessionQuestionStatus> get progressSegments {
    return [for (final question in questions) sessionStatusFor(question)];
  }
}
