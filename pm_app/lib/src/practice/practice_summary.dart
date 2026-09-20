import 'package:equatable/equatable.dart';
import 'package:pm_questions/pm_questions.dart';

import 'practice_session.dart';
import 'session_answers.dart';
import 'session_questions.dart';

/// A frozen result from a completed practice session.
///
/// Questions absent from [selectedOptionsByQuestionCode] are retained as
/// unanswered results.
final class PracticeSummary extends Equatable {
  factory PracticeSummary({
    required PracticeSession session,
    required Duration elapsedTime,
  }) {
    final summary = PracticeSummary._(
      sessionQuestions: session.questions,
      answers: session.answers,
      elapsedTime: elapsedTime,
    );
    if (summary.correctAttemptCount < summary.correctQuestionCount) {
      throw ArgumentError.value(
        summary.correctAttemptCount,
        'session.answers.correctAttemptCount',
        'Cannot be lower than the number of correctly answered questions.',
      );
    }
    if (summary.incorrectAttemptCount < summary.incorrectQuestionCount) {
      throw ArgumentError.value(
        summary.incorrectAttemptCount,
        'session.answers.incorrectAttemptCount',
        'Cannot be lower than the number of incorrectly answered questions.',
      );
    }

    return summary;
  }

  const PracticeSummary._({
    required this.sessionQuestions,
    required this.answers,
    required this.elapsedTime,
  });

  final SessionQuestions sessionQuestions;
  final SessionAnswers answers;
  final Duration elapsedTime;

  List<Question> get questions => sessionQuestions.questions;

  Map<String, QuestionOption> get selectedOptionsByQuestionCode =>
      answers.selectedOptionsByQuestionCode;

  int get correctAttemptCount => answers.correctAttemptCount;

  int get incorrectAttemptCount => answers.incorrectAttemptCount;

  int get totalQuestionCount => questions.length;

  int get answeredQuestionCount {
    return questions.where((question) {
      return selectedOptionsByQuestionCode.containsKey(question.code);
    }).length;
  }

  int get correctQuestionCount => questions.where(isCorrect).length;

  int get incorrectQuestionCount =>
      answeredQuestionCount - correctQuestionCount;

  int get unansweredQuestionCount => totalQuestionCount - answeredQuestionCount;

  double get scoreRatio =>
      totalQuestionCount == 0 ? 0 : correctQuestionCount / totalQuestionCount;

  QuestionOption? selectedOptionFor(Question question) {
    return answers.selectedOptionFor(question);
  }

  bool isCorrect(Question question) {
    final selectedOption = selectedOptionFor(question);
    return selectedOption != null && question.isCorrect(selectedOption);
  }

  @override
  List<Object?> get props => [
    PracticeSummary,
    sessionQuestions,
    answers,
    elapsedTime,
  ];
}
