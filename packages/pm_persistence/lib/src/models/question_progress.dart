import 'package:equatable/equatable.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

final class QuestionProgress extends Equatable {
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
  List<Object?> get props => [
    QuestionProgress,
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
  ];
}
