import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice/practice_question_policy.dart';
import 'package:pm_app/src/practice/widgets/session_question_status_badge.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('uses localized semantics and status icons', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpLocalizedPage(
      const Row(
        children: [
          SessionQuestionStatusBadge.navigation(
            status: SessionQuestionStatus.correct,
          ),
          SessionQuestionStatusBadge.navigation(
            status: SessionQuestionStatus.incorrect,
          ),
        ],
      ),
    );

    expect(find.bySemanticsLabel('Correcta'), findsOneWidget);
    expect(find.bySemanticsLabel('Incorrecta'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('preserves each unanswered presentation', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpLocalizedPage(
      const Row(
        children: [
          SessionQuestionStatusBadge.navigation(
            status: SessionQuestionStatus.unanswered,
          ),
          SessionQuestionStatusBadge.summary(
            status: SessionQuestionStatus.unanswered,
          ),
        ],
      ),
    );

    expect(find.bySemanticsLabel('Sin responder'), findsNWidgets(2));
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    expect(find.byIcon(Icons.horizontal_rule), findsOneWidget);
    semantics.dispose();
  });
}
