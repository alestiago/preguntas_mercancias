import 'package:pm_questions_bank/pm_questions_bank.dart';

final class QuestionProgress {
  const QuestionProgress({
    required this.questionCode,
    required this.section,
    required this.lastSelectedOption,
    required this.correctOption,
    required this.lastAnswerWasCorrect,
    required this.attempts,
    required this.correctAttempts,
    required this.incorrectAttempts,
    required this.firstAnsweredAt,
    required this.lastAnsweredAt,
  });

  final String questionCode;
  final String section;
  final QuestionOption lastSelectedOption;
  final QuestionOption correctOption;
  final bool lastAnswerWasCorrect;
  final int attempts;
  final int correctAttempts;
  final int incorrectAttempts;
  final DateTime firstAnsweredAt;
  final DateTime lastAnsweredAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuestionProgress &&
            runtimeType == other.runtimeType &&
            questionCode == other.questionCode &&
            section == other.section &&
            lastSelectedOption == other.lastSelectedOption &&
            correctOption == other.correctOption &&
            lastAnswerWasCorrect == other.lastAnswerWasCorrect &&
            attempts == other.attempts &&
            correctAttempts == other.correctAttempts &&
            incorrectAttempts == other.incorrectAttempts &&
            firstAnsweredAt == other.firstAnsweredAt &&
            lastAnsweredAt == other.lastAnsweredAt;
  }

  @override
  int get hashCode => Object.hash(
    questionCode,
    section,
    lastSelectedOption,
    correctOption,
    lastAnswerWasCorrect,
    attempts,
    correctAttempts,
    incorrectAttempts,
    firstAnsweredAt,
    lastAnsweredAt,
  );
}
