import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class PracticeSessionFooter extends StatelessWidget {
  const PracticeSessionFooter({
    super.key,
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
