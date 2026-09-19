import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../practice_question_policy.dart';

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
    required this.isCurrent,
  });

  final SessionQuestionStatus status;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resultColors = AppResultColors.of(context);

    if (isCurrent) {
      return Container(
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
      );
    }

    return SizedBox(
      height: 3,
      child: ColoredBox(
        color: status.color(
          colorScheme: colorScheme,
          resultColors: resultColors,
          isCurrent: false,
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
