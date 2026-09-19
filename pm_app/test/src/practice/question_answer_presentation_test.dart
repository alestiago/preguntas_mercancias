import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice/question_answer_presentation.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../fixtures/question_fixtures.dart';

void main() {
  test('seeded shuffle preserves canonical identities and answer texts', () {
    final question = buildQuestions().first;
    final presentation = QuestionAnswerPresentation.forSession(
      question,
      shuffleAnswers: true,
      random: Random(1),
    );

    expect(
      presentation.answers.map((answer) => answer.option).toSet(),
      QuestionOption.values.toSet(),
    );
    for (final answer in presentation.answers) {
      expect(answer, question.answerFor(answer.option));
    }
    expect(
      presentation.displayOptionFor(question.correctOption),
      isNot(question.correctOption),
    );
  });

  test('keeps positional questions in source order', () {
    final question = Question(
      code: '1A01003',
      section: '1A',
      prompt: 'Pregunta posicional',
      answers: buildQuestions().first.answers,
      correctOption: QuestionOption.d,
      norma: 'Norma',
      shuffleable: false,
    );
    final presentation = QuestionAnswerPresentation.forSession(
      question,
      shuffleAnswers: true,
      random: Random(1),
    );

    expect(
      presentation.answers.map((answer) => answer.option),
      QuestionOption.values,
    );
  });

  test('fails explicitly for an option absent from the presentation', () {
    final question = Question(
      code: '1A01004',
      section: '1A',
      prompt: 'Pregunta incompleta',
      answers: const [
        QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
      ],
      correctOption: QuestionOption.a,
      norma: 'Norma',
    );
    final presentation = QuestionAnswerPresentation.inSourceOrder(question);

    expect(
      () => presentation.displayOptionFor(QuestionOption.b),
      throwsStateError,
    );
  });
}
