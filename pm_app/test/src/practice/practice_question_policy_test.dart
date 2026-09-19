import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice/practice_question_policy.dart';
import 'package:pm_app/src/practice/practice_session_config.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../fixtures/question_fixtures.dart';

void main() {
  const policy = PracticeQuestionPolicy();

  group('PracticeQuestionPolicy', () {
    test('classifies lifetime progress using the ever-correct rule', () {
      final questions = buildHomeQuestions();
      final snapshot = QuestionProgressSnapshot(
        byQuestionCode: {
          questions[0].code: _progress(
            questions[0],
            correctAttempts: 1,
            incorrectAttempts: 1,
            lastAnswerWasCorrect: false,
          ),
          questions[1].code: _progress(
            questions[1],
            correctAttempts: 0,
            incorrectAttempts: 2,
            lastAnswerWasCorrect: false,
          ),
        },
      );

      expect(
        policy.lifetimeStatusFor(questions[0], snapshot),
        LifetimeQuestionStatus.mastered,
      );
      expect(
        policy.lifetimeStatusFor(questions[1], snapshot),
        LifetimeQuestionStatus.needsReview,
      );
      expect(
        policy.lifetimeStatusFor(questions[2], snapshot),
        LifetimeQuestionStatus.unanswered,
      );
    });

    test('summary and mode selections use the same eligibility rules', () {
      final questions = buildHomeQuestions();
      final unknownQuestion = Question(
        code: '9Z99999',
        section: '9Z',
        prompt: 'Pregunta retirada',
        answers: questions.first.answers,
        correctOption: QuestionOption.a,
        norma: 'Norma retirada',
      );
      final snapshot = QuestionProgressSnapshot(
        byQuestionCode: {
          questions[0].code: _progress(
            questions[0],
            correctAttempts: 1,
            incorrectAttempts: 1,
            lastAnswerWasCorrect: false,
          ),
          questions[1].code: _progress(
            questions[1],
            correctAttempts: 0,
            incorrectAttempts: 1,
            lastAnswerWasCorrect: false,
          ),
          unknownQuestion.code: _progress(
            unknownQuestion,
            correctAttempts: 0,
            incorrectAttempts: 1,
            lastAnswerWasCorrect: false,
          ),
        },
      );

      final catalogQuestions = [...questions, questions.last];
      final summary = policy.summarize(
        questions: catalogQuestions,
        progressSnapshot: snapshot,
      );
      final reviewQuestions = policy.selectEligible(
        questions: catalogQuestions,
        mode: PracticeMode.review,
        progressSnapshot: snapshot,
      );
      final pendingQuestions = policy.selectEligible(
        questions: catalogQuestions,
        mode: PracticeMode.pending,
        progressSnapshot: snapshot,
      );

      expect(summary.totalCount, 3);
      expect(summary.masteredCount, 1);
      expect(summary.needsReviewCount, reviewQuestions.length);
      expect(summary.unansweredCount, pendingQuestions.length);
      expect(summary.unansweredCountsBySection, {'1A': 1});
      expect(reviewQuestions.map((question) => question.code), [
        questions[1].code,
      ]);
      expect(pendingQuestions.map((question) => question.code), [
        questions[2].code,
      ]);
    });

    test('selection applies section, exclusion, and batch constraints', () {
      final questions = buildManyQuestions(5);

      final selected = policy.selectEligible(
        questions: questions,
        mode: PracticeMode.pending,
        progressSnapshot: const QuestionProgressSnapshot.empty(),
        section: '1A',
        excludedQuestionCodes: {questions.first.code},
        limit: 2,
      );

      expect(selected.map((question) => question.code), [
        questions[1].code,
        questions[2].code,
      ]);
    });

    test('classifies current-session answers separately', () {
      final question = buildQuestions().first;

      expect(
        policy.sessionStatusFor(question, null),
        SessionQuestionStatus.unanswered,
      );
      expect(
        policy.sessionStatusFor(question, QuestionOption.b),
        SessionQuestionStatus.correct,
      );
      expect(
        policy.sessionStatusFor(question, QuestionOption.a),
        SessionQuestionStatus.incorrect,
      );
    });

    test('summary data is immutable and value comparable', () {
      final sectionCounts = {'1A': 2};
      final summary = PracticeQuestionSummary(
        totalCount: 2,
        masteredCount: 0,
        needsReviewCount: 0,
        unansweredCount: 2,
        unansweredCountsBySection: sectionCounts,
      );
      final equalSummary = PracticeQuestionSummary(
        totalCount: 2,
        masteredCount: 0,
        needsReviewCount: 0,
        unansweredCount: 2,
        unansweredCountsBySection: const {'1A': 2},
      );

      sectionCounts['1A'] = 99;

      expect(summary.unansweredCountsBySection, {'1A': 2});
      expect(
        () => summary.unansweredCountsBySection.clear(),
        throwsUnsupportedError,
      );
      expect(summary, equalSummary);
      expect(summary.hashCode, equalSummary.hashCode);
    });
  });
}

QuestionProgress _progress(
  Question question, {
  required int correctAttempts,
  required int incorrectAttempts,
  required bool lastAnswerWasCorrect,
}) {
  final answeredAt = DateTime(2026);
  return QuestionProgress(
    questionCode: question.code,
    section: question.section,
    lastSelectedOption: lastAnswerWasCorrect
        ? question.correctOption
        : QuestionOption.values.firstWhere(
            (option) => option != question.correctOption,
          ),
    correctOption: question.correctOption,
    lastAnswerWasCorrect: lastAnswerWasCorrect,
    attempts: correctAttempts + incorrectAttempts,
    correctAttempts: correctAttempts,
    incorrectAttempts: incorrectAttempts,
    firstAnsweredAt: answeredAt,
    lastAnsweredAt: answeredAt,
  );
}
