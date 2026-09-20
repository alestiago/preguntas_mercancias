import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:pm_questions/pm_questions.dart';

@immutable
final class SessionAnswers extends Equatable {
  factory SessionAnswers({
    Map<String, QuestionOption> selectedOptionsByQuestionCode = const {},
    int correctAttemptCount = 0,
    int incorrectAttemptCount = 0,
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

    return SessionAnswers._(
      selectedOptionsByQuestionCode: Map.unmodifiable(
        selectedOptionsByQuestionCode,
      ),
      correctAttemptCount: correctAttemptCount,
      incorrectAttemptCount: incorrectAttemptCount,
    );
  }

  const SessionAnswers.empty()
    : selectedOptionsByQuestionCode = const {},
      correctAttemptCount = 0,
      incorrectAttemptCount = 0;

  const SessionAnswers._({
    required this.selectedOptionsByQuestionCode,
    required this.correctAttemptCount,
    required this.incorrectAttemptCount,
  });

  /// The latest retained answer result for each question in this session.
  ///
  /// Review navigation may temporarily remove an entry to reopen a retry.
  final Map<String, QuestionOption> selectedOptionsByQuestionCode;

  /// Correct attempts made in this session, including review retries.
  final int correctAttemptCount;

  /// Incorrect attempts made in this session, including review retries.
  final int incorrectAttemptCount;

  int get totalAttemptCount => correctAttemptCount + incorrectAttemptCount;

  bool get hasSelections => selectedOptionsByQuestionCode.isNotEmpty;

  QuestionOption? selectedOptionFor(Question question) {
    return selectedOptionsByQuestionCode[question.code];
  }

  SessionAnswers recordSelection(
    Question question,
    QuestionOption selectedOption,
  ) {
    if (selectedOptionsByQuestionCode.containsKey(question.code)) {
      throw StateError('Question is already answered.');
    }
    final isCorrect = question.isCorrect(selectedOption);
    return SessionAnswers(
      selectedOptionsByQuestionCode: {
        ...selectedOptionsByQuestionCode,
        question.code: selectedOption,
      },
      correctAttemptCount: correctAttemptCount + (isCorrect ? 1 : 0),
      incorrectAttemptCount: incorrectAttemptCount + (isCorrect ? 0 : 1),
    );
  }

  SessionAnswers reopenQuestion(String questionCode) {
    if (!selectedOptionsByQuestionCode.containsKey(questionCode)) {
      return this;
    }
    return SessionAnswers(
      selectedOptionsByQuestionCode: {
        for (final entry in selectedOptionsByQuestionCode.entries)
          if (entry.key != questionCode) entry.key: entry.value,
      },
      correctAttemptCount: correctAttemptCount,
      incorrectAttemptCount: incorrectAttemptCount,
    );
  }

  @override
  List<Object?> get props => [
    SessionAnswers,
    selectedOptionsByQuestionCode,
    correctAttemptCount,
    incorrectAttemptCount,
  ];
}
