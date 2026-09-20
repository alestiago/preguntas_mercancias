import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';

import 'practice_question_policy.dart';
import 'practice_session_config.dart';
import 'question_answer_presentation.dart';
import 'session_answers.dart';
import 'session_questions.dart';

@immutable
final class PracticeSession extends Equatable {
  factory PracticeSession({
    required SessionQuestions questions,
    SessionAnswers answers = const SessionAnswers.empty(),
    int currentIndex = 0,
  }) {
    if (questions.questions.isEmpty) {
      if (currentIndex != 0) {
        throw RangeError.index(
          currentIndex,
          questions.questions,
          'currentIndex',
        );
      }
    } else if (currentIndex < 0 || currentIndex >= questions.questions.length) {
      throw RangeError.index(currentIndex, questions.questions, 'currentIndex');
    }
    return PracticeSession._(
      questions: questions,
      answers: answers,
      currentIndex: currentIndex,
    );
  }

  factory PracticeSession.fromQuestions({
    required Iterable<Question> questions,
    Map<String, QuestionAnswerPresentation> presentationsByQuestionCode =
        const {},
    SessionAnswers answers = const SessionAnswers.empty(),
    int currentIndex = 0,
  }) {
    return PracticeSession(
      questions: SessionQuestions(
        questions: questions,
        presentationsByQuestionCode: presentationsByQuestionCode,
      ),
      answers: answers,
      currentIndex: currentIndex,
    );
  }

  const PracticeSession._({
    required this.questions,
    required this.answers,
    required this.currentIndex,
  });

  final SessionQuestions questions;
  final SessionAnswers answers;
  final int currentIndex;

  Question get currentQuestion => questions.questions[currentIndex];

  QuestionAnswerPresentation get currentAnswerPresentation {
    return questions.presentationsByQuestionCode[currentQuestion.code]!;
  }

  QuestionOption? get selectedOption {
    return answers.selectedOptionFor(currentQuestion);
  }

  PracticeSession recordSelection(QuestionOption selectedOption) {
    return _copyWith(
      answers: answers.recordSelection(currentQuestion, selectedOption),
    );
  }

  PracticeSession moveTo(int index) {
    if (index < 0 || index >= questions.questions.length) {
      throw RangeError.index(index, questions.questions, 'index');
    }
    return _copyWith(currentIndex: index);
  }

  PracticeSession moveToPrevious() => moveTo(currentIndex - 1);

  PracticeSession moveToNext() => moveTo(currentIndex + 1);

  PracticeSession? moveToNextEligible({
    required PracticeMode mode,
    required QuestionProgressSnapshot progressSnapshot,
  }) {
    final nextIndex = practiceQuestionPolicy.nextEligibleIndex(
      questions: questions.questions,
      currentIndex: currentIndex,
      mode: mode,
      progressSnapshot: progressSnapshot,
    );
    if (nextIndex == null) {
      return null;
    }

    final nextQuestion = questions.questions[nextIndex];
    return _copyWith(
      currentIndex: nextIndex,
      answers: mode == PracticeMode.review
          ? answers.reopenQuestion(nextQuestion.code)
          : answers,
    );
  }

  PracticeSession appendQuestions(SessionQuestions batch) {
    return _copyWith(questions: questions.append(batch));
  }

  PracticeSession restart() {
    return PracticeSession(
      questions: questions,
      answers: const SessionAnswers.empty(),
    );
  }

  PracticeSession _copyWith({
    SessionQuestions? questions,
    SessionAnswers? answers,
    int? currentIndex,
  }) {
    return PracticeSession(
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  @override
  List<Object?> get props => [
    PracticeSession,
    questions,
    answers,
    currentIndex,
  ];
}
