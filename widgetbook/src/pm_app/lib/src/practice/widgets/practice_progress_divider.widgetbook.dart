import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pm_app/component_library.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../../../support/use_case_frame.dart';

final practiceProgressDividerComponent = WidgetbookComponent(
  name: 'PracticeProgressDivider',
  useCases: [
    WidgetbookUseCase(
      name: 'Interactive',
      builder: (context) {
        final correctCount = context.knobs.int.slider(
          label: 'Correct segments',
          initialValue: 3,
          min: 0,
          max: 10,
        );
        final incorrectCount = context.knobs.int.slider(
          label: 'Incorrect segments',
          initialValue: 2,
          min: 0,
          max: 10,
        );
        final unansweredCount = context.knobs.int.slider(
          label: 'Unanswered segments',
          initialValue: 5,
          min: 0,
          max: 10,
        );
        final requestedIndex = context.knobs.int.slider(
          label: 'Current index',
          initialValue: 5,
          min: 0,
          max: 29,
        );
        final segments = [
          ...List.filled(correctCount, SessionQuestionStatus.correct),
          ...List.filled(incorrectCount, SessionQuestionStatus.incorrect),
          ...List.filled(unansweredCount, SessionQuestionStatus.unanswered),
        ];
        final currentIndex = segments.isEmpty
            ? 0
            : min(requestedIndex, segments.length - 1);

        return UseCaseFrame(
          builder: (_) => PracticeProgressDivider(
            segments: segments,
            currentIndex: currentIndex,
          ),
        );
      },
    ),
    WidgetbookUseCase.child(
      name: 'Empty',
      child: const UseCaseFrame(builder: _buildEmptyProgress),
    ),
  ],
);

Widget _buildEmptyProgress(BuildContext context) {
  return const PracticeProgressDivider(segments: [], currentIndex: 0);
}
