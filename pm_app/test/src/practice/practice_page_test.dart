import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../fixtures/question_fixtures.dart';
import '../../helpers/fake_question_progress_store.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('keeps footer pinned above scrollable content', (tester) async {
    final progressStore = FakeQuestionProgressStore();
    addTearDown(progressStore.close);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(390, 520);
    tester.view.devicePixelRatio = 1;

    await tester.pumpApp(
      loadQuestions: (_) async => [buildLongQuestion()],
      questionProgressStore: progressStore,
    );

    await tester.tap(find.byKey(const ValueKey('home-unanswered-stat')));
    await tester.pumpAndSettle();

    final footer = find.byKey(const ValueKey('practice-session-footer'));
    final footerTopBeforeScroll = tester.getTopLeft(footer).dy;
    final footerBottomBeforeScroll = tester.getBottomLeft(footer).dy;

    final lastAnswer = find.byKey(const ValueKey('answer-D'));
    for (var i = 0; i < 12; i += 1) {
      final lastAnswerBottom = tester.getBottomLeft(lastAnswer).dy;
      final footerTop = tester.getTopLeft(footer).dy;
      if (lastAnswerBottom < footerTop) {
        break;
      }
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
      await tester.pumpAndSettle();
    }

    expect(tester.getTopLeft(footer).dy, footerTopBeforeScroll);
    expect(tester.getBottomLeft(footer).dy, footerBottomBeforeScroll);
    expect(
      tester.getBottomLeft(lastAnswer).dy,
      lessThan(tester.getTopLeft(footer).dy),
    );
  });

  testWidgets('uses the displayed answer label in correctness feedback', (
    tester,
  ) async {
    final progressStore = FakeQuestionProgressStore();
    final question = buildQuestions().first;
    addTearDown(progressStore.close);

    await tester.pumpApp(
      loadQuestions: (_) async => [question],
      questionProgressStore: progressStore,
    );
    await tester.tap(find.byKey(const ValueKey('home-unanswered-stat')));
    await tester.pumpAndSettle();

    final correctButton = find.byKey(const ValueKey('answer-B'));
    expect(
      find.descendant(
        of: correctButton,
        matching: find.text(question.answerFor(QuestionOption.b).text),
      ),
      findsOneWidget,
    );
    final displayedOption = tester
        .widgetList<Text>(
          find.descendant(of: correctButton, matching: find.byType(Text)),
        )
        .map((text) => text.data)
        .whereType<String>()
        .firstWhere((text) => const {'A', 'B', 'C', 'D'}.contains(text));

    await tester.tap(find.byKey(const ValueKey('answer-A')));
    await tester.pumpAndSettle();

    expect(
      find.text('Respuesta correcta: $displayedOption. Respuesta B'),
      findsOneWidget,
    );
  });
}
