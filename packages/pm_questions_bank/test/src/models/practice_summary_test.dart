import 'package:flutter_test/flutter_test.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

void main() {
  group('PracticeSummary', () {
    final questionA = _question(
      code: '1A01001',
      correctOption: QuestionOption.b,
    );
    final questionB = _question(
      code: '1A01002',
      correctOption: QuestionOption.a,
    );

    test('reports the total question count', () {
      final summary = PracticeSummary(
        questions: [questionA, questionB],
        selectedOptionsByQuestionCode: const {},
        correctCount: 0,
        incorrectCount: 0,
        elapsedTime: Duration.zero,
      );

      expect(summary.totalCount, 2);
    });

    test('isCorrect reflects the selected option', () {
      final summary = PracticeSummary(
        questions: [questionA, questionB],
        selectedOptionsByQuestionCode: {
          questionA.code: QuestionOption.b,
          questionB.code: QuestionOption.b,
        },
        correctCount: 1,
        incorrectCount: 1,
        elapsedTime: const Duration(minutes: 5),
      );

      expect(summary.isCorrect(questionA), isTrue);
      expect(summary.isCorrect(questionB), isFalse);
    });

    test('isCorrect is false when the question was not answered', () {
      final summary = PracticeSummary(
        questions: [questionA],
        selectedOptionsByQuestionCode: const {},
        correctCount: 0,
        incorrectCount: 0,
        elapsedTime: Duration.zero,
      );

      expect(summary.isCorrect(questionA), isFalse);
    });

    test('scoreRatio divides correct answers by the total', () {
      final summary = PracticeSummary(
        questions: [questionA, questionB],
        selectedOptionsByQuestionCode: const {},
        correctCount: 1,
        incorrectCount: 1,
        elapsedTime: Duration.zero,
      );

      expect(summary.scoreRatio, 0.5);
    });

    test('scoreRatio is zero when there are no questions', () {
      const summary = PracticeSummary(
        questions: [],
        selectedOptionsByQuestionCode: {},
        correctCount: 0,
        incorrectCount: 0,
        elapsedTime: Duration.zero,
      );

      expect(summary.scoreRatio, 0);
    });

    test('supports value equality', () {
      final summaryA = PracticeSummary(
        questions: [questionA],
        selectedOptionsByQuestionCode: {questionA.code: QuestionOption.b},
        correctCount: 1,
        incorrectCount: 0,
        elapsedTime: const Duration(minutes: 1),
      );
      final summaryB = PracticeSummary(
        questions: [questionA],
        selectedOptionsByQuestionCode: {questionA.code: QuestionOption.b},
        correctCount: 1,
        incorrectCount: 0,
        elapsedTime: const Duration(minutes: 1),
      );

      expect(summaryA, summaryB);
      expect(summaryA.hashCode, summaryB.hashCode);
    });
  });
}

Question _question({
  required String code,
  required QuestionOption correctOption,
}) {
  return Question(
    code: code,
    section: '1A',
    prompt: 'Prompt for $code',
    answers: [
      for (final option in QuestionOption.values)
        QuestionAnswer(option: option, text: 'Answer ${option.code}'),
    ],
    correctOption: correctOption,
    norma: 'Norma',
  );
}
