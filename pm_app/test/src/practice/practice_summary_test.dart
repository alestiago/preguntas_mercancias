import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice/practice_summary.dart';
import 'package:pm_questions/pm_questions.dart';

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
        correctAttemptCount: 0,
        incorrectAttemptCount: 0,
        elapsedTime: Duration.zero,
      );

      expect(summary.totalQuestionCount, 2);
    });

    test('isCorrect reflects the selected option', () {
      final summary = PracticeSummary(
        questions: [questionA, questionB],
        selectedOptionsByQuestionCode: {
          questionA.code: QuestionOption.b,
          questionB.code: QuestionOption.b,
        },
        correctAttemptCount: 1,
        incorrectAttemptCount: 1,
        elapsedTime: const Duration(minutes: 5),
      );

      expect(summary.isCorrect(questionA), isTrue);
      expect(summary.isCorrect(questionB), isFalse);
    });

    test('isCorrect is false when the question was not answered', () {
      final summary = PracticeSummary(
        questions: [questionA],
        selectedOptionsByQuestionCode: const {},
        correctAttemptCount: 0,
        incorrectAttemptCount: 0,
        elapsedTime: Duration.zero,
      );

      expect(summary.isCorrect(questionA), isFalse);
    });

    test('scoreRatio divides correct answers by the total', () {
      final summary = PracticeSummary(
        questions: [questionA, questionB],
        selectedOptionsByQuestionCode: {
          questionA.code: QuestionOption.b,
          questionB.code: QuestionOption.b,
        },
        correctAttemptCount: 3,
        incorrectAttemptCount: 4,
        elapsedTime: Duration.zero,
      );

      expect(summary.scoreRatio, 0.5);
      expect(summary.answeredQuestionCount, 2);
      expect(summary.correctQuestionCount, 1);
      expect(summary.incorrectQuestionCount, 1);
      expect(summary.unansweredQuestionCount, 0);
      expect(summary.correctAttemptCount, 3);
      expect(summary.incorrectAttemptCount, 4);
    });

    test('scoreRatio is zero when there are no questions', () {
      final summary = PracticeSummary(
        questions: const [],
        selectedOptionsByQuestionCode: const {},
        correctAttemptCount: 0,
        incorrectAttemptCount: 0,
        elapsedTime: Duration.zero,
      );

      expect(summary.scoreRatio, 0);
    });

    test('supports value equality', () {
      final summaryA = PracticeSummary(
        questions: [questionA],
        selectedOptionsByQuestionCode: {questionA.code: QuestionOption.b},
        correctAttemptCount: 1,
        incorrectAttemptCount: 0,
        elapsedTime: const Duration(minutes: 1),
      );
      final summaryB = PracticeSummary(
        questions: [questionA],
        selectedOptionsByQuestionCode: {questionA.code: QuestionOption.b},
        correctAttemptCount: 1,
        incorrectAttemptCount: 0,
        elapsedTime: const Duration(minutes: 1),
      );

      expect(summaryA, summaryB);
      expect(summaryA.hashCode, summaryB.hashCode);
    });

    test('defensively copies questions and selected options', () {
      final questions = [questionA];
      final selectedOptions = {questionA.code: QuestionOption.b};
      final summary = PracticeSummary(
        questions: questions,
        selectedOptionsByQuestionCode: selectedOptions,
        correctAttemptCount: 1,
        incorrectAttemptCount: 0,
        elapsedTime: Duration.zero,
      );

      questions.clear();
      selectedOptions.clear();

      expect(summary.questions, [questionA]);
      expect(summary.selectedOptionsByQuestionCode, {
        questionA.code: QuestionOption.b,
      });
      expect(() => summary.questions.clear(), throwsUnsupportedError);
      expect(
        () => summary.selectedOptionsByQuestionCode.clear(),
        throwsUnsupportedError,
      );
    });

    test('rejects attempt totals below the selected results', () {
      expect(
        () => PracticeSummary(
          questions: [questionA],
          selectedOptionsByQuestionCode: {questionA.code: QuestionOption.b},
          correctAttemptCount: 0,
          incorrectAttemptCount: 0,
          elapsedTime: Duration.zero,
        ),
        throwsArgumentError,
      );
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
