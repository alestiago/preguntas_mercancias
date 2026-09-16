import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../l10n/app_localizations.dart';
import '../questions/load_questions.dart';
import '../practice_summary/practice_summary_page.dart';
import 'bloc/practice_bloc.dart';
import 'widgets/practice_page_app_bar.dart';
import 'widgets/practice_progress_divider.dart';
import 'widgets/practice_question_header.dart';
import 'widgets/practice_session_footer.dart';
import 'widgets/question_navigation_drawer.dart';

class QuestionPracticePage extends StatelessWidget {
  const QuestionPracticePage({
    super.key,
    LoadQuestions? loadQuestions,
    this.loadMoreQuestions,
    this.questionProgressStore,
    this.initialSection = '1A',
    this.isReviewMode = false,
    this.isPendingMode = false,
    this.isSimulacroMode = false,
    this.shuffleAnswers = true,
    this.pendingQuestionCount,
    this.pendingQuestionCountsBySection = const {},
  }) : loadQuestions = loadQuestions ?? loadQuestionsFromBank;

  final LoadQuestions loadQuestions;
  final LoadMoreQuestions? loadMoreQuestions;
  final QuestionProgressStore? questionProgressStore;
  final String? initialSection;
  final bool isReviewMode;
  final bool isPendingMode;
  final bool isSimulacroMode;
  final bool shuffleAnswers;
  final int? pendingQuestionCount;
  final Map<String, int> pendingQuestionCountsBySection;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PracticeBloc(
        loadQuestions: loadQuestions,
        loadMoreQuestions: loadMoreQuestions,
        questionProgressStore: questionProgressStore,
        initialSection: initialSection,
        isReviewMode: isReviewMode,
        isPendingMode: isPendingMode,
        isSimulacroMode: isSimulacroMode,
        shuffleAnswers: shuffleAnswers,
      )..add(const PracticeStarted()),
      child: _QuestionPracticeView(
        pendingQuestionCount: pendingQuestionCount,
        pendingQuestionCountsBySection: pendingQuestionCountsBySection,
      ),
    );
  }
}

class _QuestionPracticeView extends StatefulWidget {
  const _QuestionPracticeView({
    required this.pendingQuestionCount,
    required this.pendingQuestionCountsBySection,
  });

  final int? pendingQuestionCount;
  final Map<String, int> pendingQuestionCountsBySection;

  @override
  State<_QuestionPracticeView> createState() => _QuestionPracticeViewState();
}

class _QuestionPracticeViewState extends State<_QuestionPracticeView> {
  final DateTime _startedAt = DateTime.now();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PracticeBloc, PracticeState>(
      builder: (context, state) {
        final canPop = state is! PracticeLoaded || !state.isRecordingAnswer;
        final footerState =
            state is PracticeLoaded && state.questions.isNotEmpty
            ? state
            : null;

        return PopScope(
          canPop: canPop,
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
              onExitConfirmed: () => Navigator.of(context).pop(),
              onOpenQuestionNavigator: _openQuestionNavigator,
            ),
            bottomNavigationBar: footerState == null
                ? null
                : _PracticeSessionFooterBar(
                    child: PracticeSessionFooter(
                      answered: footerState.answered,
                      currentIndex: footerState.currentIndex,
                      isLastQuestion: footerState.isLastQuestion,
                      isFilteredPracticeMode:
                          footerState.isFilteredPracticeMode,
                      isFilteredPracticeComplete:
                          footerState.isFilteredPracticeComplete,
                      isSimulacroMode: footerState.isSimulacroMode,
                      isRecordingAnswer: footerState.isRecordingAnswer,
                      onFinishPractice: () => footerState.isSimulacroMode
                          ? _finishSimulacro(context, footerState)
                          : Navigator.of(context).pop(),
                      onNextQuestion: () => context.read<PracticeBloc>().add(
                        const NextQuestionPressed(),
                      ),
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
                      pendingQuestionCount: widget.pendingQuestionCount,
                      pendingQuestionCountsBySection:
                          widget.pendingQuestionCountsBySection,
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

  void _finishSimulacro(BuildContext context, PracticeLoaded state) {
    final summary = PracticeSummary(
      questions: state.questions,
      selectedOptionsByQuestionCode: state.selectedOptionsByQuestionCode,
      correctCount: state.correctCount,
      incorrectCount: state.incorrectCount,
      elapsedTime: DateTime.now().difference(_startedAt),
    );

    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(builder: (_) => PracticeSummaryPage(summary: summary)),
    );
  }

  void _openQuestionNavigator() {
    _scaffoldKey.currentState?.openEndDrawer();
  }
}

class _PracticeBody extends StatelessWidget {
  const _PracticeBody({
    required this.state,
    required this.pendingQuestionCount,
    required this.pendingQuestionCountsBySection,
    required this.onOpenQuestionNavigator,
  });

  final PracticeState state;
  final int? pendingQuestionCount;
  final Map<String, int> pendingQuestionCountsBySection;
  final VoidCallback? onOpenQuestionNavigator;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      PracticeLoading() => const _LoadingState(),
      PracticeLoadFailure(:final error) => _ErrorState(
        error: error,
        onRetry: () => context.read<PracticeBloc>().add(const RetryPressed()),
      ),
      PracticeLoaded(questions: final questions) when questions.isEmpty =>
        _EmptyState(
          selectedSection: state.selectedSection,
          onSectionSelected: (section) =>
              context.read<PracticeBloc>().add(SectionSelected(section)),
        ),
      PracticeLoaded loadedState => _PracticeContent(
        state: loadedState,
        pendingQuestionCount: pendingQuestionCount,
        pendingQuestionCountsBySection: pendingQuestionCountsBySection,
        onOpenQuestionNavigator: onOpenQuestionNavigator,
      ),
    };
  }
}

class _PracticeContent extends StatelessWidget {
  const _PracticeContent({
    required this.state,
    required this.pendingQuestionCount,
    required this.pendingQuestionCountsBySection,
    required this.onOpenQuestionNavigator,
  });

  final PracticeLoaded state;
  final int? pendingQuestionCount;
  final Map<String, int> pendingQuestionCountsBySection;
  final VoidCallback? onOpenQuestionNavigator;

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;
    final currentQuestionNumber = state.displayQuestionNumber;
    final questionCount = state.displayQuestionCount(
      pendingQuestionCount: pendingQuestionCount,
      pendingQuestionCountsBySection: pendingQuestionCountsBySection,
    );

    return CustomScrollView(
      slivers: [
        if (!state.isSimulacroMode)
          SliverToBoxAdapter(
            child: _SectionSelector(
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
            currentQuestionNumber: currentQuestionNumber,
            questionCount: questionCount,
            onAnswer: (option) =>
                context.read<PracticeBloc>().add(AnswerPressed(option)),
            onOpenQuestionNavigator: onOpenQuestionNavigator,
          ),
        ),
      ],
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
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PracticeContentLayout extends StatelessWidget {
  const _PracticeContentLayout({
    required this.state,
    required this.question,
    required this.currentQuestionNumber,
    required this.questionCount,
    required this.onAnswer,
    required this.onOpenQuestionNavigator,
  });

  final PracticeLoaded state;
  final Question question;
  final int currentQuestionNumber;
  final int questionCount;
  final ValueChanged<QuestionOption> onAnswer;
  final VoidCallback? onOpenQuestionNavigator;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PracticeQuestionHeader(
                question: question,
                currentQuestionNumber: currentQuestionNumber,
                questionCount: questionCount,
                onOpenQuestionNavigator: onOpenQuestionNavigator,
              ),
              _QuestionPanel(
                question: question,
                selectedOption: state.selectedOption,
                onAnswer: onAnswer,
              ),
              const SizedBox(height: 16),
              _AnswerFeedbackSwitcher(
                answered: state.answered,
                question: question,
                selectedOption: state.selectedOption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerFeedbackSwitcher extends StatelessWidget {
  const _AnswerFeedbackSwitcher({
    required this.answered,
    required this.question,
    required this.selectedOption,
  });

  final bool answered;
  final Question question;
  final QuestionOption? selectedOption;

  @override
  Widget build(BuildContext context) {
    final selectedOption = this.selectedOption;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: answered && selectedOption != null
          ? _AnswerFeedback(
              key: ValueKey(selectedOption),
              question: question,
              selectedOption: selectedOption,
            )
          : const SizedBox.shrink(),
    );
  }
}

class _SectionSelector extends StatelessWidget {
  const _SectionSelector({
    required this.selectedSection,
    required this.onSectionSelected,
  });

  final String? selectedSection;
  final ValueChanged<String?> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            ChoiceChip(
              label: Text(localizations.allSections),
              selected: selectedSection == null,
              onSelected: (_) => onSectionSelected(null),
            ),
            const SizedBox(width: 8),
            for (final section in QuestionBankLoader.sections) ...[
              ChoiceChip(
                label: Text(section),
                selected: selectedSection == section,
                onSelected: (_) => onSectionSelected(section),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionPanel extends StatelessWidget {
  const _QuestionPanel({
    required this.question,
    required this.selectedOption,
    required this.onAnswer,
  });

  final Question question;
  final QuestionOption? selectedOption;
  final ValueChanged<QuestionOption> onAnswer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              question.prompt,
              style: textTheme.titleLarge?.copyWith(
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            for (
              var index = 0;
              index < question.answers.length;
              index += 1
            ) ...[
              _AnswerOptionButton(
                answer: question.answers[index],
                displayOption: QuestionOption.values[index],
                correctOption: question.correctOption,
                selectedOption: selectedOption,
                onPressed: () => onAnswer(question.answers[index].option),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnswerOptionButton extends StatelessWidget {
  const _AnswerOptionButton({
    required this.answer,
    required this.displayOption,
    required this.correctOption,
    required this.selectedOption,
    required this.onPressed,
  });

  final QuestionAnswer answer;
  final QuestionOption displayOption;
  final QuestionOption correctOption;
  final QuestionOption? selectedOption;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final answered = selectedOption != null;
    final selected = selectedOption == answer.option;
    final correct = correctOption == answer.option;
    final optionStyle = _AnswerOptionStyle.forState(
      colorScheme: colorScheme,
      answered: answered,
      selected: selected,
      correct: correct,
    );

    return OutlinedButton(
      key: ValueKey('answer-${answer.option.code}'),
      onPressed: answered ? null : onPressed,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: optionStyle.backgroundColor,
        disabledBackgroundColor: optionStyle.backgroundColor,
        foregroundColor: optionStyle.foregroundColor,
        disabledForegroundColor: optionStyle.foregroundColor,
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        side: BorderSide(
          color: optionStyle.borderColor,
          width: answered ? 1.4 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _AnswerOptionButtonContent(
        answer: answer,
        displayOption: displayOption,
        selected: selected,
        correct: answered && correct,
        trailingIcon: optionStyle.trailingIcon,
      ),
    );
  }
}

class _AnswerOptionButtonContent extends StatelessWidget {
  const _AnswerOptionButtonContent({
    required this.answer,
    required this.displayOption,
    required this.selected,
    required this.correct,
    required this.trailingIcon,
  });

  final QuestionAnswer answer;
  final QuestionOption displayOption;
  final bool selected;
  final bool correct;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _OptionBadge(
          option: displayOption,
          selected: selected,
          correct: correct,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            answer.text,
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.25),
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 10),
          Icon(trailingIcon),
        ],
      ],
    );
  }
}

final class _AnswerOptionStyle {
  const _AnswerOptionStyle({
    required this.borderColor,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.trailingIcon,
  });

  final Color borderColor;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? trailingIcon;

  factory _AnswerOptionStyle.forState({
    required ColorScheme colorScheme,
    required bool answered,
    required bool selected,
    required bool correct,
  }) {
    if (answered && correct) {
      return const _AnswerOptionStyle(
        borderColor: Color(0xFF2E7D32),
        backgroundColor: Color(0xFFE8F5E9),
        foregroundColor: Color(0xFF1B5E20),
        trailingIcon: Icons.check_circle,
      );
    }

    if (answered && selected) {
      return const _AnswerOptionStyle(
        borderColor: Color(0xFFC62828),
        backgroundColor: Color(0xFFFFEBEE),
        foregroundColor: Color(0xFFB71C1C),
        trailingIcon: Icons.cancel,
      );
    }

    return _AnswerOptionStyle(
      borderColor: colorScheme.outlineVariant,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      trailingIcon: null,
    );
  }
}

class _OptionBadge extends StatelessWidget {
  const _OptionBadge({
    required this.option,
    required this.selected,
    required this.correct,
  });

  final QuestionOption option;
  final bool selected;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = correct || selected
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = correct || selected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return CircleAvatar(
      radius: 16,
      backgroundColor: backgroundColor,
      child: Text(
        option.code,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AnswerFeedback extends StatelessWidget {
  const _AnswerFeedback({
    super.key,
    required this.question,
    required this.selectedOption,
  });

  final Question question;
  final QuestionOption selectedOption;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isCorrect = question.isCorrect(selectedOption);
    final correctDisplayOption = question.displayOptionFor(
      question.correctOption,
    );
    final feedbackStyle = _AnswerFeedbackStyle.forResult(isCorrect: isCorrect);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: feedbackStyle.backgroundColor,
        border: Border.all(color: feedbackStyle.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnswerFeedbackHeader(
              title: isCorrect
                  ? localizations.correctAnswerFeedbackTitle
                  : localizations.incorrectAnswerFeedbackTitle,
              icon: feedbackStyle.icon,
              foregroundColor: feedbackStyle.foregroundColor,
            ),
            const SizedBox(height: 10),
            _CorrectAnswerDetails(
              correctDisplayOption: correctDisplayOption,
              correctAnswerText: question.correctAnswer.text,
              norma: question.norma,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerFeedbackHeader extends StatelessWidget {
  const _AnswerFeedbackHeader({
    required this.title,
    required this.icon,
    required this.foregroundColor,
  });

  final String title;
  final IconData icon;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: foregroundColor),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: foregroundColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CorrectAnswerDetails extends StatelessWidget {
  const _CorrectAnswerDetails({
    required this.correctDisplayOption,
    required this.correctAnswerText,
    required this.norma,
  });

  final QuestionOption correctDisplayOption;
  final String correctAnswerText;
  final String norma;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.correctAnswer(
            correctDisplayOption.code,
            correctAnswerText,
          ),
          style: const TextStyle(fontWeight: FontWeight.w600, height: 1.25),
        ),
        const SizedBox(height: 8),
        Text(
          localizations.normReference(norma),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }
}

final class _AnswerFeedbackStyle {
  const _AnswerFeedbackStyle({
    required this.icon,
    required this.borderColor,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final Color borderColor;
  final Color backgroundColor;
  final Color foregroundColor;

  factory _AnswerFeedbackStyle.forResult({required bool isCorrect}) {
    return isCorrect
        ? const _AnswerFeedbackStyle(
            icon: Icons.check_circle,
            borderColor: Color(0xFF2E7D32),
            backgroundColor: Color(0xFFE8F5E9),
            foregroundColor: Color(0xFF1B5E20),
          )
        : const _AnswerFeedbackStyle(
            icon: Icons.cancel,
            borderColor: Color(0xFFC62828),
            backgroundColor: Color(0xFFFFEBEE),
            foregroundColor: Color(0xFFB71C1C),
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
              localizations.practiceLoadFailure,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.selectedSection,
    required this.onSectionSelected,
  });

  final String? selectedSection;
  final ValueChanged<String?> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        _SectionSelector(
          selectedSection: selectedSection,
          onSectionSelected: onSectionSelected,
        ),
        Expanded(
          child: Center(child: Text(localizations.noQuestionsAvailable)),
        ),
      ],
    );
  }
}

extension _PracticeLoadedPresentation on PracticeLoaded {
  int get displayQuestionNumber => currentIndex + 1;

  int displayQuestionCount({
    required int? pendingQuestionCount,
    required Map<String, int> pendingQuestionCountsBySection,
  }) {
    if (!isPendingMode) {
      return questions.length;
    }

    final selectedSection = this.selectedSection;
    if (selectedSection != null) {
      return pendingQuestionCountsBySection[selectedSection] ??
          questions.length;
    }

    return pendingQuestionCount ?? questions.length;
  }

  List<PracticeProgressSegmentStatus> get progressSegments {
    return [
      for (final question in questions)
        switch (selectedOptionsByQuestionCode[question.code]) {
          null => PracticeProgressSegmentStatus.pending,
          final selectedOption =>
            question.isCorrect(selectedOption)
                ? PracticeProgressSegmentStatus.correct
                : PracticeProgressSegmentStatus.incorrect,
        },
    ];
  }
}

extension _QuestionDisplayOptions on Question {
  QuestionOption displayOptionFor(QuestionOption option) {
    final answerIndex = answers.indexWhere((answer) => answer.option == option);
    if (answerIndex < 0 || answerIndex >= QuestionOption.values.length) {
      return option;
    }

    return QuestionOption.values[answerIndex];
  }
}
