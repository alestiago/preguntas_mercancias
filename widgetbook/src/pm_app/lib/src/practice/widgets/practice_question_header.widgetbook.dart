import 'dart:math';

import 'package:pm_app/component_library.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../../../../support/callback_notification.dart';
import '../../../../../support/fixture_factory.dart';
import '../../../../../support/use_case_frame.dart';

final practiceQuestionHeaderComponent = WidgetbookComponent(
  name: 'PracticeQuestionHeader',
  useCases: [
    WidgetbookUseCase(
      name: 'Interactive',
      builder: (context) {
        final questionCount = context.knobs.int.slider(
          label: 'Question count',
          initialValue: 30,
          min: 1,
          max: 50,
        );
        final requestedQuestionNumber = context.knobs.int.slider(
          label: 'Current question number',
          initialValue: 4,
          min: 1,
          max: 50,
        );
        final navigatorEnabled = context.knobs.boolean(
          label: 'Navigator enabled',
          initialValue: true,
        );

        return UseCaseFrame(
          builder: (context) => PracticeQuestionHeader(
            question: WidgetbookFixtures.question(),
            currentQuestionNumber: min(requestedQuestionNumber, questionCount),
            questionCount: questionCount,
            onOpenQuestionNavigator: navigatorEnabled
                ? () => showCallbackNotification(
                    context,
                    'onOpenQuestionNavigator',
                  )
                : null,
          ),
        );
      },
    ),
    WidgetbookUseCase(
      name: 'Long question code',
      builder: (_) => UseCaseFrame(
        builder: (context) => PracticeQuestionHeader(
          question: WidgetbookFixtures.question(section: 'SECCION-MUY-LARGA'),
          currentQuestionNumber: 12,
          questionCount: 30,
          onOpenQuestionNavigator: () =>
              showCallbackNotification(context, 'onOpenQuestionNavigator'),
        ),
      ),
    ),
  ],
);
