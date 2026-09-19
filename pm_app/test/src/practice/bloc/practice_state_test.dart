import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice/bloc/practice_bloc.dart';
import 'package:pm_app/src/practice/practice_session_config.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../../fixtures/question_fixtures.dart';

void main() {
  group('PracticeLoaded', () {
    test('defensively copies collection inputs', () {
      final questions = buildQuestions();
      final selections = <String, QuestionOption>{
        questions.first.code: QuestionOption.b,
      };
      final state = PracticeLoaded(
        selectedSection: '1A',
        session: const PracticeSessionConfig.standard(),
        questions: questions,
        selectedOptionsByQuestionCode: selections,
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
      final stateA = PracticeLoaded(
        selectedSection: '1A',
        session: const PracticeSessionConfig.standard(),
        questions: buildQuestions(),
        selectedOptionsByQuestionCode: const {'1A01001': QuestionOption.b},
        correctAttemptCount: 1,
        incorrectAttemptCount: 2,
      );
      final stateB = PracticeLoaded(
        selectedSection: '1A',
        session: const PracticeSessionConfig.standard(),
        questions: buildQuestions(),
        selectedOptionsByQuestionCode: const {'1A01001': QuestionOption.b},
        correctAttemptCount: 1,
        incorrectAttemptCount: 2,
      );

      expect(stateA, stateB);
      expect(stateA.hashCode, stateB.hashCode);
      expect(stateA.copyWith(currentIndex: 1), isNot(stateA));
    });

    test('keeps attempt totals when a review selection is reopened', () {
      final state = PracticeLoaded(
        selectedSection: null,
        session: const PracticeSessionConfig.review(),
        questions: [buildQuestions().first],
        selectedOptionsByQuestionCode: const {'1A01001': QuestionOption.a},
        correctAttemptCount: 1,
        incorrectAttemptCount: 2,
      );

      final reopened = state.copyWith(selectedOptionsByQuestionCode: const {});

      expect(reopened.answered, isFalse);
      expect(reopened.correctAttemptCount, 1);
      expect(reopened.incorrectAttemptCount, 2);
    });

    test('exposes a finish action that permits earlier skipped questions', () {
      final questions = buildQuestions();
      final state = PracticeLoaded(
        selectedSection: null,
        session: const PracticeSessionConfig.simulacro(),
        questions: questions,
        currentIndex: 1,
        selectedOptionsByQuestionCode: {questions.last.code: QuestionOption.a},
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
      final unanswered = PracticeLoaded(
        selectedSection: null,
        session: const PracticeSessionConfig.simulacro(),
        questions: questions,
        currentIndex: 1,
      );
      final saving = unanswered.copyWith(
        selectedOptionsByQuestionCode: {questions.last.code: QuestionOption.a},
        isRecordingAnswer: true,
      );

      expect(unanswered.primaryAction, PracticePrimaryAction.finish);
      expect(unanswered.isPrimaryActionEnabled, isFalse);
      expect(saving.isPrimaryActionEnabled, isFalse);
      expect(saving.exitPolicy, PracticeExitPolicy.blocked);
    });

    test('uses the same confirmation policy for every simulacro exit', () {
      final question = buildQuestions().first;
      final state = PracticeLoaded(
        selectedSection: null,
        session: const PracticeSessionConfig.simulacro(),
        questions: [question],
        selectedOptionsByQuestionCode: {question.code: QuestionOption.b},
      );

      expect(state.exitPolicy, PracticeExitPolicy.confirm);
    });
  });
}
