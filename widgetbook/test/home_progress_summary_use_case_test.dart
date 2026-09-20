import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/component_library.dart';

import '../src/support/callback_notification.dart';
import '../src/support/fixture_factory.dart';
import '../src/support/use_case_frame.dart';

void main() {
  testWidgets('reports a production widget callback in the UI', (tester) async {
    await tester.pumpWidget(
      _testApp(
        HomeProgressSummary(
          state: WidgetbookFixtures.homeProgress(
            correctCount: 2,
            incorrectCount: 1,
            unansweredCount: 3,
          ),
          onStartSimulacroPractice: () {},
          onStartReviewPractice: () {},
          onStartPendingPractice: () {},
        ),
        callbackKey: const ValueKey('start-simulacro-button'),
        callbackName: 'onStartSimulacroPractice',
      ),
    );

    await tester.tap(find.byKey(const ValueKey('start-simulacro-button')));
    await tester.pump();

    expect(find.text('onStartSimulacroPractice called'), findsOneWidget);
  });

  testWidgets('keeps a zero-count review callback disabled', (tester) async {
    await tester.pumpWidget(
      _testApp(
        HomeProgressSummary(
          state: WidgetbookFixtures.homeProgress(
            correctCount: 2,
            incorrectCount: 0,
            unansweredCount: 3,
          ),
          onStartSimulacroPractice: () {},
          onStartReviewPractice: () {},
          onStartPendingPractice: () {},
        ),
        callbackKey: const ValueKey('home-incorrect-stat'),
        callbackName: 'onStartReviewPractice',
      ),
    );

    await tester.tap(find.byKey(const ValueKey('home-incorrect-stat')));
    await tester.pump();

    expect(find.byKey(callbackNotificationKey), findsNothing);
  });
}

Widget _testApp(
  HomeProgressSummary summary, {
  required Key callbackKey,
  required String callbackName,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('es'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: UseCaseFrame(
      builder: (context) => HomeProgressSummary(
        state: summary.state,
        onStartSimulacroPractice:
            callbackKey == const ValueKey('start-simulacro-button')
            ? () => showCallbackNotification(context, callbackName)
            : summary.onStartSimulacroPractice,
        onStartReviewPractice:
            callbackKey == const ValueKey('home-incorrect-stat')
            ? () => showCallbackNotification(context, callbackName)
            : summary.onStartReviewPractice,
        onStartPendingPractice: summary.onStartPendingPractice,
      ),
    ),
  );
}
