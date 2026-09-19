import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../l10n/app_localizations.dart';
import '../../app/theme/app_theme.dart';
import '../practice_question_policy.dart';
import '../session_question_status_localizations.dart';

class PracticeProgressDivider extends StatelessWidget {
  const PracticeProgressDivider({
    super.key,
    required this.segments,
    required this.currentIndex,
  });

  final List<SessionQuestionStatus> segments;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 7,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var index = 0; index < segments.length; index += 1)
            Expanded(
              child: _PracticeProgressSegment(
                status: segments[index],
                questionNumber: index + 1,
                questionCount: segments.length,
                isCurrent: index == currentIndex,
              ),
            ),
        ],
      ),
    );
  }
}

class _PracticeProgressSegment extends StatelessWidget {
  const _PracticeProgressSegment({
    required this.status,
    required this.questionNumber,
    required this.questionCount,
    required this.isCurrent,
  });

  final SessionQuestionStatus status;
  final int questionNumber;
  final int questionCount;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resultColors = AppResultColors.of(context);
    final localizations = AppLocalizations.of(context);
    final semanticsLabel = localizations.questionProgressStatus(
      questionNumber,
      questionCount,
      status.localizedLabel(localizations),
    );

    if (isCurrent) {
      return Semantics(
        container: true,
        label: semanticsLabel,
        selected: true,
        sortKey: OrdinalSortKey(questionNumber.toDouble()),
        child: Container(
          height: 7,
          decoration: BoxDecoration(
            color: status.color(
              colorScheme: colorScheme,
              resultColors: resultColors,
              isCurrent: true,
            ),
            border: Border.all(color: colorScheme.surface),
            borderRadius: BorderRadius.circular(AppLayout.pillRadius),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: semanticsLabel,
      sortKey: OrdinalSortKey(questionNumber.toDouble()),
      child: SizedBox(
        height: 3,
        child: ColoredBox(
          color: status.color(
            colorScheme: colorScheme,
            resultColors: resultColors,
            isCurrent: false,
          ),
        ),
      ),
    );
  }
}

extension _SessionQuestionStatusProgressColor on SessionQuestionStatus {
  Color color({
    required ColorScheme colorScheme,
    required AppResultColors resultColors,
    required bool isCurrent,
  }) {
    return switch (this) {
      _ when isCurrent => colorScheme.primary,
      SessionQuestionStatus.correct ||
      SessionQuestionStatus.incorrect => resultColors.correct,
      SessionQuestionStatus.unanswered => colorScheme.outline,
    };
  }
}
