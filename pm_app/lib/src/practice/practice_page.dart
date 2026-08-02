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
    this.questionProgressStore,
    this.initialSection = '1A',
    this.isReviewMode = false,
  }) : loadQuestions = loadQuestions ?? loadQuestionsFromBank;

  final LoadQuestions loadQuestions;
  final QuestionProgressStore? questionProgressStore;
  final String? initialSection;
  final bool isReviewMode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PracticeBloc(
        loadQuestions: loadQuestions,
        questionProgressStore: questionProgressStore,
        initialSection: initialSection,
        isReviewMode: isReviewMode,
      )..add(const PracticeStarted()),
      child: const _QuestionPracticeView(),
    );
  }
}

class _QuestionPracticeView extends StatelessWidget {
  const _QuestionPracticeView();

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
              title: Text(localizations.appTitle),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _ScorePill(
                    correctCount: state.correctCount,
                    incorrectCount: state.incorrectCount,
                    answeredQuestionCount:
                        state.progressSnapshot.answeredQuestionCount,
                  ),
                ),
              ],
            ),
            body: SafeArea(child: _PracticeBody(state: state)),
          ),
        );
      },
    );
  }
}

class _PracticeBody extends StatelessWidget {
  const _PracticeBody({required this.state});

  final PracticeState state;

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
      PracticeLoaded loadedState => _PracticeContent(state: loadedState),
    };
  }
}

class _PracticeContent extends StatelessWidget {
  const _PracticeContent({required this.state});

  final PracticeLoaded state;

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;

    return CustomScrollView(
      slivers: [
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
                      currentIndex: state.currentIndex,
                      questionCount: state.questions.length,
                      progress: state.progress,
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
                      isLastQuestion: state.isLastQuestion,
                      isReviewMode: state.isReviewMode,
                      isReviewComplete: state.isReviewComplete,
                      isRecordingAnswer: state.isRecordingAnswer,
                      correctCount: state.correctCount,
                      incorrectCount: state.incorrectCount,
                      onFinishPractice: () => Navigator.of(context).pop(),
                      onNextQuestion: () => context.read<PracticeBloc>().add(
                        const NextQuestionPressed(),
                      ),
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
    required this.currentIndex,
    required this.questionCount,
    required this.progress,
  });

  final Question question;
  final int currentIndex;
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
              localizations.questionProgress(currentIndex + 1, questionCount),
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
            for (final answer in question.answers) ...[
              _AnswerOptionButton(
                answer: answer,
                correctOption: question.correctOption,
                selectedOption: selectedOption,
                onPressed: () => onAnswer(answer.option),
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
    required this.correctOption,
    required this.selectedOption,
    required this.onPressed,
  });

  final QuestionAnswer answer;
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
            option: answer.option,
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
                question.correctOption.code,
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

class _SessionFooter extends StatelessWidget {
  const _SessionFooter({
    required this.answered,
    required this.isLastQuestion,
    required this.isReviewMode,
    required this.isReviewComplete,
    required this.isRecordingAnswer,
    required this.correctCount,
    required this.incorrectCount,
    required this.onFinishPractice,
    required this.onNextQuestion,
  });

  final bool answered;
  final bool isLastQuestion;
  final bool isReviewMode;
  final bool isReviewComplete;
  final bool isRecordingAnswer;
  final int correctCount;
  final int incorrectCount;
  final VoidCallback onFinishPractice;
  final VoidCallback onNextQuestion;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);

    final isFinishAction = isReviewComplete;
    final isRestartAction = isLastQuestion && !isReviewMode;

    return Row(
      children: [
        Expanded(
          child: Text(
            localizations.sessionScore(correctCount, incorrectCount),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton.icon(
          key: const ValueKey('next-question-button'),
          onPressed: answered && !isRecordingAnswer
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

class _ScorePill extends StatelessWidget {
  const _ScorePill({
    required this.correctCount,
    required this.incorrectCount,
    required this.answeredQuestionCount,
  });

  final int correctCount;
  final int incorrectCount;
  final int answeredQuestionCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);

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
            incorrectCount,
            answeredQuestionCount,
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
