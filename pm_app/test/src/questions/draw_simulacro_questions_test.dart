import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/questions/draw_simulacro_questions.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

void main() {
  group('drawSimulacroQuestions', () {
    test('draws thirty questions balanced across standard sections', () {
      final questions = _questionsBySection(questionCountBySection: 8);

      final simulacroQuestions = drawSimulacroQuestions(
        questions,
        random: Random(1),
      );

      expect(simulacroQuestions, hasLength(30));
      expect(
        simulacroQuestions.map((question) => question.code).toSet(),
        hasLength(30),
      );

      final questionCountBySection = _questionCountBySection(
        simulacroQuestions,
      );

      expect(
        questionCountBySection.keys,
        unorderedEquals(QuestionBankLoader.sections),
      );
      expect(
        questionCountBySection.values.where((count) => count == 4),
        hasLength(6),
      );
      expect(
        questionCountBySection.values.where((count) => count == 3),
        hasLength(2),
      );
    });

    test('tops up from other sections when a section has fewer questions', () {
      final questions = _questionsBySection(
        questionCountBySection: 8,
        overrides: const {'1A': 1},
      );

      final simulacroQuestions = drawSimulacroQuestions(
        questions,
        random: Random(1),
      );

      expect(simulacroQuestions, hasLength(30));
      expect(
        simulacroQuestions.map((question) => question.code).toSet(),
        hasLength(30),
      );
      expect(
        simulacroQuestions.where((question) => question.section == '1A'),
        hasLength(1),
      );
    });
  });
}

Map<String, int> _questionCountBySection(List<Question> questions) {
  final questionCountBySection = <String, int>{};
  for (final question in questions) {
    questionCountBySection.update(
      question.section,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }

  return questionCountBySection;
}

List<Question> _questionsBySection({
  required int questionCountBySection,
  Map<String, int> overrides = const {},
}) {
  return [
    for (final section in QuestionBankLoader.sections)
      for (
        var questionNumber = 1;
        questionNumber <= (overrides[section] ?? questionCountBySection);
        questionNumber += 1
      )
        _question(section: section, questionNumber: questionNumber),
  ];
}

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
