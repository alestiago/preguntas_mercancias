import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../l10n/app_localizations.dart';
import 'bloc/practice_bloc.dart';
import '../questions/load_questions.dart';

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

class _QuestionPracticeView extends StatelessWidget {
  const _QuestionPracticeView({
    required this.pendingQuestionCount,
    required this.pendingQuestionCountsBySection,
  });

  final int? pendingQuestionCount;
  final Map<String, int> pendingQuestionCountsBySection;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PracticeBloc, PracticeState>(
      builder: (context, state) {
        final localizations = AppLocalizations.of(context);
        final canPop = state is! PracticeLoaded || !state.isRecordingAnswer;

        return PopScope(
          canPop: canPop,
          child: Scaffold(
            appBar: AppBar(
              title: state.isSimulacroMode
                  ? _SimulacroModeTitle(
                      title: _practiceTitle(localizations, state),
                    )
                  : Text(_practiceTitle(localizations, state)),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _ScorePill(
                    correctCount: state.correctCount,
                    answeredQuestionCount:
                        state.correctCount + state.incorrectCount,
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: _PracticeBody(
                state: state,
                pendingQuestionCount: pendingQuestionCount,
                pendingQuestionCountsBySection: pendingQuestionCountsBySection,
              ),
            ),
          ),
        );
      },
    );
  }

  String _practiceTitle(AppLocalizations localizations, PracticeState state) {
    if (state.isPendingMode) {
      return localizations.pendingQuestions;
    }

    if (state.isReviewMode) {
      return 'Por Repasar';
    }

    if (state.isSimulacroMode) {
      return localizations.startSimulacro;
    }

    return localizations.appTitle;
  }
}

class _PracticeBody extends StatelessWidget {
  const _PracticeBody({
    required this.state,
    required this.pendingQuestionCount,
    required this.pendingQuestionCountsBySection,
  });

  final PracticeState state;
  final int? pendingQuestionCount;
  final Map<String, int> pendingQuestionCountsBySection;

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
      ),
    };
  }
}

class _PracticeContent extends StatelessWidget {
  const _PracticeContent({
    required this.state,
    required this.pendingQuestionCount,
    required this.pendingQuestionCountsBySection,
  });

  final PracticeLoaded state;
  final int? pendingQuestionCount;
  final Map<String, int> pendingQuestionCountsBySection;

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;
    final currentQuestionNumber = _currentQuestionNumber;
    final questionCount = _questionCount;

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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _QuestionProgress(
                      question: question,
                      currentQuestionNumber: currentQuestionNumber,
                      questionCount: questionCount,
                      progress: _progress(currentQuestionNumber, questionCount),
                    ),
                    const SizedBox(height: 18),
                    _QuestionPanel(
                      question: question,
                      selectedOption: state.selectedOption,
                      onAnswer: (option) => context.read<PracticeBloc>().add(
                        AnswerPressed(option),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: state.answered
                          ? _AnswerFeedback(
                              key: ValueKey(state.selectedOption),
                              question: question,
                              selectedOption: state.selectedOption!,
                            )
                          : const SizedBox.shrink(),
                    ),
                    const Spacer(),
                    const SizedBox(height: 20),
                    _SessionFooter(
                      answered: state.answered,
                      currentIndex: state.currentIndex,
                      isLastQuestion: state.isLastQuestion,
                      isFilteredPracticeMode: state.isFilteredPracticeMode,
                      isFilteredPracticeComplete:
                          state.isFilteredPracticeComplete,
                      isSimulacroMode: state.isSimulacroMode,
                      isRecordingAnswer: state.isRecordingAnswer,
                      onFinishPractice: () => Navigator.of(context).pop(),
                      onNextQuestion: () => context.read<PracticeBloc>().add(
                        const NextQuestionPressed(),
                      ),
                      onPreviousQuestion: () => context
                          .read<PracticeBloc>()
                          .add(const PreviousQuestionPressed()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  int get _currentQuestionNumber => state.currentIndex + 1;

  int get _questionCount {
    if (!state.isPendingMode) {
      return state.questions.length;
    }

    final selectedSection = state.selectedSection;
    if (selectedSection != null) {
      return pendingQuestionCountsBySection[selectedSection] ??
          state.questions.length;
    }

    return pendingQuestionCount ?? state.questions.length;
  }

  double _progress(int currentQuestionNumber, int questionCount) {
    if (!state.isPendingMode) {
      return state.progress;
    }

    if (questionCount == 0) {
      return 0;
    }

    return (currentQuestionNumber / questionCount).clamp(0, 1).toDouble();
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

class _QuestionProgress extends StatelessWidget {
  const _QuestionProgress({
    required this.question,
    required this.currentQuestionNumber,
    required this.questionCount,
    required this.progress,
  });

  final Question question;
  final int currentQuestionNumber;
  final int questionCount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              question.code,
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              localizations.questionProgress(
                currentQuestionNumber,
                questionCount,
              ),
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: progress),
      ],
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
    final Color borderColor;
    final Color backgroundColor;
    final Color foregroundColor;
    final IconData? trailingIcon;

    if (answered && correct) {
      borderColor = const Color(0xFF2E7D32);
      backgroundColor = const Color(0xFFE8F5E9);
      foregroundColor = const Color(0xFF1B5E20);
      trailingIcon = Icons.check_circle;
    } else if (answered && selected) {
      borderColor = const Color(0xFFC62828);
      backgroundColor = const Color(0xFFFFEBEE);
      foregroundColor = const Color(0xFFB71C1C);
      trailingIcon = Icons.cancel;
    } else {
      borderColor = colorScheme.outlineVariant;
      backgroundColor = colorScheme.surface;
      foregroundColor = colorScheme.onSurface;
      trailingIcon = null;
    }

    return OutlinedButton(
      key: ValueKey('answer-${answer.option.code}'),
      onPressed: answered ? null : onPressed,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: backgroundColor,
        disabledBackgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        disabledForegroundColor: foregroundColor,
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        side: BorderSide(color: borderColor, width: answered ? 1.4 : 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        children: [
          _OptionBadge(
            option: displayOption,
            selected: selected,
            correct: answered && correct,
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
      ),
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
    final correctDisplayOption = _displayOptionFor(
      question,
      question.correctOption,
    );
    final title = isCorrect
        ? localizations.correctAnswerFeedbackTitle
        : localizations.incorrectAnswerFeedbackTitle;
    final icon = isCorrect ? Icons.check_circle : Icons.cancel;
    final borderColor = isCorrect
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    final backgroundColor = isCorrect
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);
    final foregroundColor = isCorrect
        ? const Color(0xFF1B5E20)
        : const Color(0xFFB71C1C);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            ),
            const SizedBox(height: 10),
            Text(
              localizations.correctAnswer(
                correctDisplayOption.code,
                question.correctAnswer.text,
              ),
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.25),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.normReference(question.norma),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

QuestionOption _displayOptionFor(Question question, QuestionOption option) {
  final answerIndex = question.answers.indexWhere(
    (answer) => answer.option == option,
  );
  if (answerIndex < 0 || answerIndex >= QuestionOption.values.length) {
    return option;
  }

  return QuestionOption.values[answerIndex];
}

class _SessionFooter extends StatelessWidget {
  const _SessionFooter({
    required this.answered,
    required this.currentIndex,
    required this.isLastQuestion,
    required this.isFilteredPracticeMode,
    required this.isFilteredPracticeComplete,
    required this.isSimulacroMode,
    required this.isRecordingAnswer,
    required this.onFinishPractice,
    required this.onNextQuestion,
    required this.onPreviousQuestion,
  });

  final bool answered;
  final int currentIndex;
  final bool isLastQuestion;
  final bool isFilteredPracticeMode;
  final bool isFilteredPracticeComplete;
  final bool isSimulacroMode;
  final bool isRecordingAnswer;
  final VoidCallback onFinishPractice;
  final VoidCallback onNextQuestion;
  final VoidCallback onPreviousQuestion;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final isFinishAction =
        isFilteredPracticeComplete || (isSimulacroMode && isLastQuestion);
    final isRestartAction =
        isLastQuestion && !isFilteredPracticeMode && !isSimulacroMode;
    final isTerminalAction = isFinishAction || isRestartAction;

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: OutlinedButton.icon(
            key: const ValueKey('previous-question-button'),
            onPressed: currentIndex > 0 && !isRecordingAnswer
                ? onPreviousQuestion
                : null,
            icon: const Icon(Icons.arrow_back),
            label: Text(localizations.previousQuestion),
          ),
        ),
        const Spacer(),
        FilledButton.icon(
          key: const ValueKey('next-question-button'),
          onPressed: !isRecordingAnswer && (answered || !isTerminalAction)
              ? (isFinishAction ? onFinishPractice : onNextQuestion)
              : null,
          icon: Icon(
            isFinishAction
                ? Icons.check
                : isRestartAction
                ? Icons.refresh
                : Icons.arrow_forward,
          ),
          label: Text(
            isFinishAction
                ? localizations.finishPractice
                : isRestartAction
                ? localizations.restartPractice
                : localizations.nextQuestion,
          ),
        ),
      ],
    );
  }
}

class _SimulacroModeTitle extends StatelessWidget {
  const _SimulacroModeTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: .center,
      crossAxisAlignment: .start,
      children: [
        Center(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: .center,
          ),
        ),
        Center(child: const _SimulacroElapsedTimer()),
      ],
    );
  }
}

class _SimulacroElapsedTimer extends StatefulWidget {
  const _SimulacroElapsedTimer();

  @override
  State<_SimulacroElapsedTimer> createState() => _SimulacroElapsedTimerState();
}

class _SimulacroElapsedTimerState extends State<_SimulacroElapsedTimer> {
  Timer? _timer;
  var _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      key: const ValueKey('simulacro-elapsed-time'),
      _formatDuration(_elapsed),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      textAlign: .center,
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({
    required this.correctCount,
    required this.answeredQuestionCount,
  });

  final int correctCount;
  final int answeredQuestionCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);
    final scorePercentage = answeredQuestionCount == 0
        ? 0
        : ((correctCount / answeredQuestionCount) * 100).round();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          localizations.scorePill(
            correctCount,
            answeredQuestionCount,
            scorePercentage,
          ),
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w800,
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
