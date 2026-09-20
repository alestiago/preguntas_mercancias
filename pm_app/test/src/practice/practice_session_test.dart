import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice/practice_session.dart';
import 'package:pm_app/src/practice/practice_session_config.dart';
import 'package:pm_app/src/practice/question_answer_presentation.dart';
import 'package:pm_app/src/practice/session_answers.dart';
import 'package:pm_app/src/practice/session_questions.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../fixtures/question_fixtures.dart';

void main() {
  group('SessionAnswers', () {
    test('records attempts and defensively freezes retained selections', () {
      final question = buildQuestions().first;
      final selections = <String, QuestionOption>{};
      final empty = SessionAnswers(selectedOptionsByQuestionCode: selections);
      selections[question.code] = QuestionOption.a;

      final incorrect = empty.recordSelection(question, QuestionOption.a);

      expect(empty.selectedOptionsByQuestionCode, isEmpty);
      expect(incorrect.selectedOptionFor(question), QuestionOption.a);
      expect(incorrect.correctAttemptCount, 0);
      expect(incorrect.incorrectAttemptCount, 1);
      expect(incorrect.totalAttemptCount, 1);
      expect(
        () => incorrect.selectedOptionsByQuestionCode.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => incorrect.recordSelection(question, QuestionOption.b),
        throwsStateError,
      );
    });

    test('reopens review selection without changing attempt totals', () {
      final question = buildQuestions().first;
      final answered = SessionAnswers(
        selectedOptionsByQuestionCode: {question.code: QuestionOption.a},
        correctAttemptCount: 1,
        incorrectAttemptCount: 3,
      );

      final reopened = answered.reopenQuestion(question.code);

      expect(reopened.selectedOptionsByQuestionCode, isEmpty);
      expect(reopened.correctAttemptCount, 1);
      expect(reopened.incorrectAttemptCount, 3);
    });
  });

  group('SessionQuestions', () {
    test('freezes questions and keeps presentations stable when appending', () {
      final questions = buildQuestions();
      final firstPresentation = QuestionAnswerPresentation.forSession(
        questions.first,
        shuffleAnswers: true,
        random: Random(1),
      );
      final initial = SessionQuestions(
        questions: [questions.first],
        presentationsByQuestionCode: {questions.first.code: firstPresentation},
      );
      final appended = initial.append(
        SessionQuestions(questions: [questions.last]),
      );

      expect(() => initial.questions.clear(), throwsUnsupportedError);
      expect(appended.questions, questions);
      expect(
        identical(
          appended.presentationsByQuestionCode[questions.first.code],
          firstPresentation,
        ),
        isTrue,
      );
    });
  });

  group('PracticeSession', () {
    test('navigation reuses immutable questions and presentations', () {
      final session = PracticeSession.fromQuestions(
        questions: buildQuestions(),
      );

      final moved = session.moveToNext();
      final returned = moved.moveToPrevious();

      expect(identical(moved.questions, session.questions), isTrue);
      expect(identical(returned.questions, session.questions), isTrue);
      expect(moved.currentIndex, 1);
      expect(returned.currentIndex, 0);
    });

    test('review navigation reopens retries but retains attempt totals', () {
      final question = buildQuestions().first;
      final session = PracticeSession.fromQuestions(
        questions: [question],
        answers: SessionAnswers(
          selectedOptionsByQuestionCode: {question.code: QuestionOption.a},
          incorrectAttemptCount: 1,
        ),
      );

      final moved = session.moveToNextEligible(
        mode: PracticeMode.review,
        progressSnapshot: QuestionProgressSnapshot(
          byQuestionCode: {question.code: _incorrectProgress(question)},
        ),
      );

      expect(moved, isNotNull);
      expect(moved!.answers.selectedOptionsByQuestionCode, isEmpty);
      expect(moved.answers.incorrectAttemptCount, 1);
    });

    test('restart clears answers and retains the frozen question set', () {
      final question = buildQuestions().first;
      final session = PracticeSession.fromQuestions(
        questions: buildQuestions(),
        currentIndex: 1,
        answers: SessionAnswers(
          selectedOptionsByQuestionCode: {
            question.code: question.correctOption,
          },
          correctAttemptCount: 1,
        ),
      );

      final restarted = session.restart();

      expect(restarted.currentIndex, 0);
      expect(restarted.answers, const SessionAnswers.empty());
      expect(identical(restarted.questions, session.questions), isTrue);
    });
  });
}

QuestionProgress _incorrectProgress(Question question) {
  final answeredAt = DateTime.utc(2026);
  return QuestionProgress(
    questionCode: question.code,
    section: question.section,
    lastSelectedOption: QuestionOption.a,
    correctOption: question.correctOption,
    lastAnswerWasCorrect: false,
    attempts: 1,
    correctAttempts: 0,
    incorrectAttempts: 1,
    firstAnsweredAt: answeredAt,
    lastAnsweredAt: answeredAt,
  );
}
