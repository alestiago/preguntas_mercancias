import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/main.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import 'helpers/fake_question_progress_store.dart';
import 'helpers/fake_settings_store.dart';

void main() {
  testWidgets('answers a question and advances to the next one', (
    tester,
  ) async {
    final progressStore = FakeQuestionProgressStore();
    addTearDown(progressStore.close);

    await tester.pumpWidget(
      PreguntasMercanciasApp(
        loadQuestions: (_) async => _questions,
        questionProgressStore: progressStore,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(find.text('2 preguntas en el banco'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-unanswered-count')), findsOneWidget);

    expect(find.byKey(const ValueKey('start-practice-button')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home-unanswered-stat')));
    await tester.pumpAndSettle();

    expect(find.text('Primera pregunta'), findsOneWidget);
    final answerButtons = find.byType(OutlinedButton);
    expect(answerButtons, findsNWidgets(4));
    expect(
      find.descendant(of: answerButtons.at(0), matching: find.text('A')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: answerButtons.at(1), matching: find.text('B')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: answerButtons.at(2), matching: find.text('C')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: answerButtons.at(3), matching: find.text('D')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('answer-A')));
    await tester.pumpAndSettle();

    expect(find.text('Incorrecta'), findsOneWidget);
    expect(find.textContaining('Respuesta correcta:'), findsOneWidget);
    expect(find.text('0/1 (0%)'), findsOneWidget);

    final nextButton = find.byKey(const ValueKey('next-question-button'));
    await tester.ensureVisible(nextButton);
    await tester.pumpAndSettle();
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(find.text('Segunda pregunta'), findsOneWidget);

    Navigator.of(tester.element(find.text('Segunda pregunta'))).pop();
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-incorrect-stat')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-unanswered-stat')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('home-unanswered-stat')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('answer-A')));
    await tester.pumpAndSettle();

    expect(find.text('Finalizar'), findsOneWidget);
    expect(find.text('1/1 (100%)'), findsOneWidget);

    await tester.ensureVisible(nextButton);
    await tester.pumpAndSettle();
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-correct-stat')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-incorrect-stat')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-unanswered-stat')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows answer history with the most recent answer first', (
    tester,
  ) async {
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

    await tester.pumpWidget(
      PreguntasMercanciasApp(
        loadQuestions: (_) async => _questions,
        questionProgressStore: progressStore,
      ),
    );
    await tester.pumpAndSettle();

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

    final newerQuestionTop = tester
        .getTopLeft(find.text('Segunda pregunta'))
        .dy;
    final olderQuestionTop = tester
        .getTopLeft(find.text('Primera pregunta'))
        .dy;
    expect(newerQuestionTop, lessThan(olderQuestionTop));

    await tester.tap(find.text('Segunda pregunta'));
    await tester.pumpAndSettle();

    expect(find.text('Segunda pregunta'), findsOneWidget);
    expect(find.text('Primera pregunta'), findsNothing);
    expect(find.text('Pregunta 1 de 1'), findsOneWidget);
    expect(find.text('Todas'), findsNothing);
  });

  testWidgets('settings shows version and resets progress', (tester) async {
    final progressStore = FakeQuestionProgressStore();
    addTearDown(progressStore.close);
    final settingsStore = FakeSettingsStore();
    addTearDown(settingsStore.close);
    await progressStore.recordAnswer(
      QuestionAnswerRecord(
        questionCode: '1A01001',
        section: '1A',
        selectedOption: QuestionOption.b,
        correctOption: QuestionOption.b,
      ),
    );
    await progressStore.recordAnswer(
      QuestionAnswerRecord(
        questionCode: '1A01002',
        section: '1A',
        selectedOption: QuestionOption.b,
        correctOption: QuestionOption.a,
      ),
    );

    await tester.pumpWidget(
      PreguntasMercanciasApp(
        loadQuestions: (_) async => _questions,
        questionProgressStore: progressStore,
        settingsStore: settingsStore,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-button')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-correct-stat')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-incorrect-stat')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Versión'), findsOneWidget);
    expect(find.text('1.0.0+1'), findsOneWidget);
    expect(find.byKey(const ValueKey('reset-progress-tile')), findsOneWidget);

    final shuffleSwitchFinder = find.byKey(
      const ValueKey('shuffle-answers-switch'),
    );
    expect(shuffleSwitchFinder, findsOneWidget);
    expect(tester.widget<SwitchListTile>(shuffleSwitchFinder).value, isTrue);

    await tester.tap(shuffleSwitchFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(shuffleSwitchFinder).value, isFalse);
    expect(await settingsStore.loadAnswerShuffleEnabled(), isFalse);

    await tester.tap(find.byKey(const ValueKey('reset-progress-tile')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Se borrarán tus respuestas y estadísticas. Esta acción no se puede deshacer.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('confirm-reset-progress-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Progreso reiniciado'), findsOneWidget);
    expect(progressStore.recordedAnswers, isEmpty);

    Navigator.of(tester.element(find.text('Ajustes'))).pop();
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-correct-stat')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-incorrect-stat')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-unanswered-stat')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('starts review practice from the questions to review stat', (
    tester,
  ) async {
    final progressStore = FakeQuestionProgressStore();
    final loadCalls = <String?>[];
    addTearDown(progressStore.close);
    await progressStore.recordAnswer(
      QuestionAnswerRecord(
        questionCode: '1B01001',
        section: '1B',
        selectedOption: QuestionOption.a,
        correctOption: QuestionOption.b,
      ),
    );

    await tester.pumpWidget(
      PreguntasMercanciasApp(
        loadQuestions: (section) {
          loadCalls.add(section);
          return _loadFilteredQuestions(section);
        },
        questionProgressStore: progressStore,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-incorrect-stat')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('home-incorrect-stat')));
    await tester.pumpAndSettle();

    expect(find.text('Por Repasar'), findsOneWidget);
    expect(find.text('Pregunta 1B'), findsOneWidget);
    expect(find.text('Pregunta 1A'), findsNothing);
    expect(find.text('Pregunta 1 de 1'), findsOneWidget);
    expect(loadCalls, [null]);

    await tester.tap(find.byKey(const ValueKey('answer-B')));
    await tester.pumpAndSettle();

    expect(find.text('Finalizar'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('next-question-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('next-question-button')));
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-incorrect-stat')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('starts pending practice from the pending questions stat', (
    tester,
  ) async {
    final progressStore = FakeQuestionProgressStore();
    final loadCalls = <String?>[];
    addTearDown(progressStore.close);
    await progressStore.recordAnswer(
      QuestionAnswerRecord(
        questionCode: '1A01001',
        section: '1A',
        selectedOption: QuestionOption.b,
        correctOption: QuestionOption.b,
      ),
    );

    await tester.pumpWidget(
      PreguntasMercanciasApp(
        loadQuestions: (section) {
          loadCalls.add(section);
          return _loadFilteredQuestions(section);
        },
        questionProgressStore: progressStore,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-unanswered-stat')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('home-unanswered-stat')));
    await tester.pumpAndSettle();

    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('Pregunta 1B'), findsOneWidget);
    expect(find.text('Pregunta 1A'), findsNothing);
    expect(find.text('Pregunta 1 de 1'), findsOneWidget);
    expect(loadCalls, [null]);

    await tester.tap(find.byKey(const ValueKey('answer-B')));
    await tester.pumpAndSettle();

    expect(find.text('Finalizar'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('next-question-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('next-question-button')));
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-unanswered-stat')),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('starts pending practice with a ten question batch', (
    tester,
  ) async {
    final progressStore = FakeQuestionProgressStore();
    final loadCalls = <String?>[];
    final questions = _manyQuestions(15);
    addTearDown(progressStore.close);

    await tester.pumpWidget(
      PreguntasMercanciasApp(
        loadQuestions: (section) {
          loadCalls.add(section);
          return Future.value(
            section == null
                ? questions
                : questions
                      .where((question) => question.section == section)
                      .toList(growable: false),
          );
        },
        questionProgressStore: progressStore,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('home-unanswered-stat')),
        matching: find.text('15'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('home-unanswered-stat')));
    await tester.pumpAndSettle();

    expect(find.text('Pregunta 1'), findsOneWidget);
    expect(find.text('Pregunta 1 de 15'), findsOneWidget);
    expect(loadCalls, [null]);

    for (var questionNumber = 1; questionNumber <= 5; questionNumber += 1) {
      await tester.tap(find.byKey(const ValueKey('answer-A')));
      await tester.pumpAndSettle();

      final nextButton = find.byKey(const ValueKey('next-question-button'));
      await tester.ensureVisible(nextButton);
      await tester.pumpAndSettle();
      await tester.tap(nextButton);
      await tester.pumpAndSettle();
    }

    expect(find.text('Pregunta 6'), findsOneWidget);
    expect(find.text('Pregunta 6 de 15'), findsOneWidget);
  });

  testWidgets('starts a thirty question simulacro from the home page', (
    tester,
  ) async {
    final progressStore = FakeQuestionProgressStore();
    addTearDown(progressStore.close);
    await progressStore.recordAnswer(
      QuestionAnswerRecord(
        questionCode: _simulacroQuestions.first.code,
        section: _simulacroQuestions.first.section,
        selectedOption: QuestionOption.a,
        correctOption: QuestionOption.a,
      ),
    );

    await tester.pumpWidget(
      PreguntasMercanciasApp(
        loadQuestions: (_) async => _simulacroQuestions,
        questionProgressStore: progressStore,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('start-simulacro-button')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('start-simulacro-button')),
        matching: find.text('30'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('start-simulacro-button')));
    await tester.pumpAndSettle();

    expect(find.text('Simulacro'), findsOneWidget);
    expect(find.text('Pregunta 1 de 30'), findsOneWidget);
    expect(find.text('0/0 (0%)'), findsOneWidget);
    expect(find.text('Tiempo 00:00'), findsOneWidget);
    expect(find.text('Todas'), findsNothing);

    await tester.pump(const Duration(seconds: 61));

    expect(find.text('Tiempo 01:01'), findsOneWidget);
  });
}

final _questions = [
  Question(
    code: '1A01001',
    section: '1A',
    prompt: 'Primera pregunta',
    answers: const [
      QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
      QuestionAnswer(option: QuestionOption.b, text: 'Respuesta B'),
      QuestionAnswer(option: QuestionOption.c, text: 'Respuesta C'),
      QuestionAnswer(option: QuestionOption.d, text: 'Respuesta D'),
    ],
    correctOption: QuestionOption.b,
    norma: 'Norma primera',
  ),
  Question(
    code: '1A01002',
    section: '1A',
    prompt: 'Segunda pregunta',
    answers: const [
      QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
      QuestionAnswer(option: QuestionOption.b, text: 'Respuesta B'),
      QuestionAnswer(option: QuestionOption.c, text: 'Respuesta C'),
      QuestionAnswer(option: QuestionOption.d, text: 'Respuesta D'),
    ],
    correctOption: QuestionOption.a,
    norma: 'Norma segunda',
  ),
];

Future<List<Question>> _loadFilteredQuestions(String? section) async {
  return section == null
      ? _reviewQuestions
      : _reviewQuestions
            .where((question) => question.section == section)
            .toList(growable: false);
}

final _reviewQuestions = [
  Question(
    code: '1A01001',
    section: '1A',
    prompt: 'Pregunta 1A',
    answers: const [
      QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
      QuestionAnswer(option: QuestionOption.b, text: 'Respuesta B'),
      QuestionAnswer(option: QuestionOption.c, text: 'Respuesta C'),
      QuestionAnswer(option: QuestionOption.d, text: 'Respuesta D'),
    ],
    correctOption: QuestionOption.b,
    norma: 'Norma primera',
  ),
  Question(
    code: '1B01001',
    section: '1B',
    prompt: 'Pregunta 1B',
    answers: const [
      QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
      QuestionAnswer(option: QuestionOption.b, text: 'Respuesta B'),
      QuestionAnswer(option: QuestionOption.c, text: 'Respuesta C'),
      QuestionAnswer(option: QuestionOption.d, text: 'Respuesta D'),
    ],
    correctOption: QuestionOption.b,
    norma: 'Norma segunda',
  ),
];

List<Question> _manyQuestions(int count) {
  return List<Question>.generate(count, (index) {
    final questionNumber = index + 1;
    return Question(
      code: '1A${questionNumber.toString().padLeft(5, '0')}',
      section: '1A',
      prompt: 'Pregunta $questionNumber',
      answers: const [
        QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
        QuestionAnswer(option: QuestionOption.b, text: 'Respuesta B'),
        QuestionAnswer(option: QuestionOption.c, text: 'Respuesta C'),
        QuestionAnswer(option: QuestionOption.d, text: 'Respuesta D'),
      ],
      correctOption: QuestionOption.a,
      norma: 'Norma',
    );
  });
}

final _simulacroQuestions = [
  for (final section in QuestionBankLoader.sections)
    for (var questionNumber = 1; questionNumber <= 8; questionNumber += 1)
      _question(section: section, questionNumber: questionNumber),
];

Question _question({required String section, required int questionNumber}) {
  return Question(
    code: '$section${questionNumber.toString().padLeft(5, '0')}',
    section: section,
    prompt: '$section pregunta $questionNumber',
    answers: const [
      QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
      QuestionAnswer(option: QuestionOption.b, text: 'Respuesta B'),
      QuestionAnswer(option: QuestionOption.c, text: 'Respuesta C'),
      QuestionAnswer(option: QuestionOption.d, text: 'Respuesta D'),
    ],
    correctOption: QuestionOption.a,
    norma: 'Norma',
  );
}
