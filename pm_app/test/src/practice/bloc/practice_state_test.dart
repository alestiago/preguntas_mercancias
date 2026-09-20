import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice/bloc/practice_bloc.dart';
import 'package:pm_app/src/practice/practice_session.dart';
import 'package:pm_app/src/practice/practice_session_config.dart';
import 'package:pm_app/src/practice/session_answers.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../../fixtures/question_fixtures.dart';

void main() {
  group('PracticeLoaded', () {
    test('exposes immutable session collections', () {
      final questions = buildQuestions();
      final selections = <String, QuestionOption>{
        questions.first.code: QuestionOption.b,
      };
      final state = _state(
        questions: questions,
        selections: selections,
        correctAttempts: 1,
      );

      questions.clear();
      selections.clear();

      expect(state.questions, hasLength(2));
      expect(state.selectedOptionsByQuestionCode, {
        '1A01001': QuestionOption.b,
      });
      expect(() => state.questions.clear(), throwsUnsupportedError);
      expect(
        () => state.selectedOptionsByQuestionCode.clear(),
        throwsUnsupportedError,
      );
    });

    test('uses deep value equality for meaningful session data', () {
      final stateA = _state(
        selections: const {'1A01001': QuestionOption.b},
        correctAttempts: 1,
        incorrectAttempts: 2,
      );
      final stateB = _state(
        selections: const {'1A01001': QuestionOption.b},
        correctAttempts: 1,
        incorrectAttempts: 2,
      );

      expect(stateA, stateB);
      expect(stateA.hashCode, stateB.hashCode);
      expect(
        stateA.copyWith(practiceSession: stateA.practiceSession.moveTo(1)),
        isNot(stateA),
      );
    });

    test('keeps attempt totals when a review selection is reopened', () {
      final state = _state(
        config: const PracticeSessionConfig.review(),
        questions: [buildQuestions().first],
        selections: const {'1A01001': QuestionOption.a},
        correctAttempts: 1,
        incorrectAttempts: 2,
      );

      final reopened = state.copyWith(
        practiceSession: PracticeSession(
          questions: state.practiceSession.questions,
          answers: state.answers.reopenQuestion('1A01001'),
        ),
      );

      expect(reopened.answered, isFalse);
      expect(reopened.correctAttemptCount, 1);
      expect(reopened.incorrectAttemptCount, 2);
    });

    test('exposes a finish action that permits earlier skipped questions', () {
      final questions = buildQuestions();
      final state = _state(
        config: const PracticeSessionConfig.simulacro(),
        questions: questions,
        currentIndex: 1,
        selections: {questions.last.code: QuestionOption.a},
        correctAttempts: 1,
      );

      expect(
        state.completionPolicy,
        PracticeCompletionPolicy.finishAtTerminalQuestionAllowingSkipped,
      );
      expect(state.primaryAction, PracticePrimaryAction.finish);
      expect(state.isPrimaryActionEnabled, isTrue);
    });

    test('disables a terminal action until the current answer is saved', () {
      final questions = buildQuestions();
      final unanswered = _state(
        config: const PracticeSessionConfig.simulacro(),
        questions: questions,
        currentIndex: 1,
      );
      final saving = _state(
        config: const PracticeSessionConfig.simulacro(),
        questions: questions,
        currentIndex: 1,
        selections: {questions.last.code: QuestionOption.a},
        correctAttempts: 1,
        isRecordingAnswer: true,
      );

      expect(unanswered.primaryAction, PracticePrimaryAction.finish);
      expect(unanswered.isPrimaryActionEnabled, isFalse);
      expect(saving.isPrimaryActionEnabled, isFalse);
      expect(saving.exitPolicy, PracticeExitPolicy.blocked);
    });

    test('uses the same confirmation policy for every simulacro exit', () {
      final question = buildQuestions().first;
      final state = _state(
        config: const PracticeSessionConfig.simulacro(),
        questions: [question],
        selections: {question.code: QuestionOption.b},
        correctAttempts: 1,
      );

      expect(state.exitPolicy, PracticeExitPolicy.confirm);
    });
  });
}

PracticeLoaded _state({
  PracticeSessionConfig config = const PracticeSessionConfig.standard(),
  List<Question>? questions,
  int currentIndex = 0,
  Map<String, QuestionOption> selections = const {},
  int correctAttempts = 0,
  int incorrectAttempts = 0,
  bool isRecordingAnswer = false,
}) {
  return PracticeLoaded(
    selectedSection: config.initialSection,
    session: config,
    practiceSession: PracticeSession.fromQuestions(
      questions: questions ?? buildQuestions(),
      currentIndex: currentIndex,
      answers: SessionAnswers(
        selectedOptionsByQuestionCode: selections,
        correctAttemptCount: correctAttempts,
        incorrectAttemptCount: incorrectAttempts,
      ),
    ),
    isRecordingAnswer: isRecordingAnswer,
  );
}
