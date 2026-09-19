import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../practice_session_config.dart';

class PracticeSessionFooter extends StatelessWidget {
  const PracticeSessionFooter({
    super.key,
    required this.answered,
    required this.currentIndex,
    required this.isLastQuestion,
    required this.isFilteredPracticeComplete,
    required this.mode,
    required this.isRecordingAnswer,
    required this.onFinishPractice,
    required this.onNextQuestion,
    required this.onPreviousQuestion,
  });

  final bool answered;
  final int currentIndex;
  final bool isLastQuestion;
  final bool isFilteredPracticeComplete;
  final PracticeMode mode;
  final bool isRecordingAnswer;
  final VoidCallback onFinishPractice;
  final VoidCallback onNextQuestion;
  final VoidCallback onPreviousQuestion;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final isFilteredPracticeMode =
        mode == PracticeMode.review || mode == PracticeMode.pending;
    final finishesAtLastQuestion =
        mode == PracticeMode.simulacro || mode == PracticeMode.singleQuestion;
    final isFinishAction =
        isFilteredPracticeComplete ||
        (finishesAtLastQuestion && isLastQuestion);
    final isRestartAction =
        isLastQuestion && !isFilteredPracticeMode && !finishesAtLastQuestion;
    final isTerminalAction = isFinishAction || isRestartAction;

    return Row(
      children: [
        const Spacer(),
        Flexible(
          fit: FlexFit.loose,
          child: OutlinedButton.icon(
            key: const ValueKey('previous-question-button'),
            onPressed: currentIndex > 0 && !isRecordingAnswer
                ? onPreviousQuestion
                : null,
            icon: const Icon(Icons.arrow_back),
            label: Text(
              localizations.previousQuestion,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          fit: FlexFit.loose,
          child: FilledButton.icon(
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
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
