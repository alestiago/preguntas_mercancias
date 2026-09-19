import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/home/bloc/home_bloc.dart';
import 'package:pm_app/src/home/widgets/home_progress_summary.dart';
import 'package:pm_persistence/pm_persistence.dart';

import '../../../fixtures/question_fixtures.dart';
import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('starts pending practice from the extracted summary', (
    tester,
  ) async {
    var pendingStarted = false;
    final state = HomeLoaded(
      questions: buildQuestions(),
      progressSnapshot: const QuestionProgressSnapshot.empty(),
    );

    await tester.pumpLocalizedPage(
      Scaffold(
        body: HomeProgressSummary(
          state: state,
          onStartSimulacroPractice: () {},
          onStartReviewPractice: () {},
          onStartPendingPractice: () => pendingStarted = true,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('home-progress-bar')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-unanswered-stat')));

    expect(pendingStarted, isTrue);
  });
}
