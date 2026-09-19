import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../fixtures/question_fixtures.dart';
import '../../helpers/fake_question_progress_store.dart';
import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows the most recent answer first', (tester) async {
    final progressStore = FakeQuestionProgressStore();
    addTearDown(progressStore.close);
    await progressStore.recordAnswer(
      QuestionAnswerRecord(
        questionCode: '1A01001',
        section: '1A',
        selectedOption: QuestionOption.a,
        correctOption: QuestionOption.b,
        answeredAt: DateTime(2026, 8, 2, 10),
      ),
    );
    await progressStore.recordAnswer(
      QuestionAnswerRecord(
        questionCode: '1A01002',
        section: '1A',
        selectedOption: QuestionOption.a,
        correctOption: QuestionOption.a,
        answeredAt: DateTime(2026, 8, 2, 11),
      ),
    );

    await tester.pumpApp(
      loadQuestions: (_) async => buildQuestions(),
      questionProgressStore: progressStore,
    );

    await tester.tap(find.byKey(const ValueKey('answer-history-button')));
    await tester.pumpAndSettle();

    expect(find.text('Historial'), findsOneWidget);
    expect(find.text('dom 2 ago 2026'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('answer-history-date-header-dom 2 ago 2026'),
        ),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(find.text('Segunda pregunta'), findsOneWidget);
    expect(find.text('Primera pregunta'), findsOneWidget);
    expect(find.text('Elegida: Respuesta A'), findsNWidgets(2));
    expect(find.textContaining('Correcta:'), findsNothing);
    expect(find.text('1A01002 · 11:00'), findsOneWidget);
    expect(find.text('11:00'), findsNothing);
    final selectedAnswerText = tester.widget<Text>(
      find.text('Elegida: Respuesta A').first,
    );
    expect(selectedAnswerText.maxLines, 1);
    expect(selectedAnswerText.overflow, TextOverflow.ellipsis);
    expect(find.text('dom 2 ago 2026 11:00'), findsNothing);

    expect(
      tester.getTopLeft(find.text('Segunda pregunta')).dy,
      lessThan(tester.getTopLeft(find.text('Primera pregunta')).dy),
    );

    await tester.tap(find.text('Segunda pregunta'));
    await tester.pumpAndSettle();

    expect(find.text('Segunda pregunta'), findsOneWidget);
    expect(find.text('Primera pregunta'), findsNothing);
    expect(find.text('Pregunta 1 de 1'), findsOneWidget);
    expect(find.text('Todas'), findsNothing);
  });
}
