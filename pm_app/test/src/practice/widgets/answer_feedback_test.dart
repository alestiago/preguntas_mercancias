import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/l10n/app_localizations.dart';
import 'package:pm_app/src/app/theme/app_theme.dart';
import 'package:pm_app/src/practice/question_answer_presentation.dart';
import 'package:pm_app/src/practice/widgets/answer_feedback.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../../fixtures/question_fixtures.dart';

void main() {
  testWidgets('announces feedback at narrow widths with large text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    final question = buildLongQuestion();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: AnswerFeedbackSwitcher(
              answered: true,
              question: question,
              answerPresentation: QuestionAnswerPresentation.inSourceOrder(
                question,
              ),
              selectedOption: QuestionOption.b,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(RegExp('Incorrecta.*Respuesta correcta')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
