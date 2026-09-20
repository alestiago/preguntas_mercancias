import 'package:flutter/material.dart';
import 'package:pm_app/component_library.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../../../support/callback_notification.dart';
import '../../../../../support/fixture_factory.dart';
import '../../../../../support/use_case_frame.dart';

final homeProgressSummaryComponent = WidgetbookComponent(
  name: 'HomeProgressSummary',
  useCases: [
    WidgetbookUseCase(
      name: 'Interactive',
      builder: (context) {
        final correctCount = context.knobs.int.slider(
          label: 'Correct questions',
          initialValue: 12,
          min: 0,
          max: 30,
        );
        final incorrectCount = context.knobs.int.slider(
          label: 'Questions to review',
          initialValue: 5,
          min: 0,
          max: 30,
        );
        final unansweredCount = context.knobs.int.slider(
          label: 'Pending questions',
          initialValue: 13,
          min: 0,
          max: 30,
        );

        return _homeProgressUseCase(
          correctCount: correctCount,
          incorrectCount: incorrectCount,
          unansweredCount: unansweredCount,
        );
      },
    ),
    WidgetbookUseCase(
      name: 'No progress',
      builder: (_) => _homeProgressUseCase(
        correctCount: 0,
        incorrectCount: 0,
        unansweredCount: 30,
      ),
    ),
    WidgetbookUseCase(
      name: 'All mastered',
      builder: (_) => _homeProgressUseCase(
        correctCount: 30,
        incorrectCount: 0,
        unansweredCount: 0,
      ),
    ),
    WidgetbookUseCase(
      name: 'Needs review',
      builder: (_) => _homeProgressUseCase(
        correctCount: 7,
        incorrectCount: 18,
        unansweredCount: 5,
      ),
    ),
  ],
);

Widget _homeProgressUseCase({
  required int correctCount,
  required int incorrectCount,
  required int unansweredCount,
}) {
  final state = WidgetbookFixtures.homeProgress(
    correctCount: correctCount,
    incorrectCount: incorrectCount,
    unansweredCount: unansweredCount,
  );

  return UseCaseFrame(
    builder: (context) => HomeProgressSummary(
      state: state,
      onStartSimulacroPractice: () =>
          showCallbackNotification(context, 'onStartSimulacroPractice'),
      onStartReviewPractice: () =>
          showCallbackNotification(context, 'onStartReviewPractice'),
      onStartPendingPractice: () =>
          showCallbackNotification(context, 'onStartPendingPractice'),
    ),
  );
}
