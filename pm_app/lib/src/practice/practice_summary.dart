import 'package:equatable/equatable.dart';
import 'package:pm_questions/pm_questions.dart';

/// A snapshot of the results of a completed practice session.
///
/// Questions absent from [selectedOptionsByQuestionCode] are retained as
/// unanswered results.
final class PracticeSummary extends Equatable {
  factory PracticeSummary({
    required Iterable<Question> questions,
    required Map<String, QuestionOption> selectedOptionsByQuestionCode,
    required int correctAttemptCount,
    required int incorrectAttemptCount,
    required Duration elapsedTime,
  }) {
    if (correctAttemptCount < 0) {
      throw ArgumentError.value(
        correctAttemptCount,
        'correctAttemptCount',
        'Must not be negative.',
      );
    }
    if (incorrectAttemptCount < 0) {
      throw ArgumentError.value(
        incorrectAttemptCount,
        'incorrectAttemptCount',
        'Must not be negative.',
      );
    }

    final summary = PracticeSummary._(
      questions: List.unmodifiable(questions),
      selectedOptionsByQuestionCode: Map.unmodifiable(
        selectedOptionsByQuestionCode,
      ),
      correctAttemptCount: correctAttemptCount,
      incorrectAttemptCount: incorrectAttemptCount,
      elapsedTime: elapsedTime,
    );
    if (correctAttemptCount < summary.correctQuestionCount) {
      throw ArgumentError.value(
        correctAttemptCount,
        'correctAttemptCount',
        'Cannot be lower than the number of correctly answered questions.',
      );
    }
    if (incorrectAttemptCount < summary.incorrectQuestionCount) {
      throw ArgumentError.value(
        incorrectAttemptCount,
        'incorrectAttemptCount',
        'Cannot be lower than the number of incorrectly answered questions.',
      );
    }

    return summary;
  }

  const PracticeSummary._({
    required this.questions,
    required this.selectedOptionsByQuestionCode,
    required this.correctAttemptCount,
    required this.incorrectAttemptCount,
    required this.elapsedTime,
  });

  final List<Question> questions;
  final Map<String, QuestionOption> selectedOptionsByQuestionCode;

  /// All correct attempts made during the session, including retries.
  final int correctAttemptCount;

  /// All incorrect attempts made during the session, including retries.
  final int incorrectAttemptCount;
  final Duration elapsedTime;

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

  QuestionOption? selectedOptionFor(Question question) =>
      selectedOptionsByQuestionCode[question.code];

  bool isCorrect(Question question) {
    final selectedOption = selectedOptionFor(question);
    return selectedOption != null && question.isCorrect(selectedOption);
  }

  @override
  List<Object?> get props => [
    PracticeSummary,
    questions,
    selectedOptionsByQuestionCode,
    correctAttemptCount,
    incorrectAttemptCount,
    elapsedTime,
  ];
}
