import 'package:pm_questions_bank/pm_questions_bank.dart';

final class QuestionAnswerRecord {
  QuestionAnswerRecord({
    required this.questionCode,
    required this.section,
    required this.selectedOption,
    required this.correctOption,
    DateTime? answeredAt,
  }) : answeredAt = answeredAt ?? DateTime.now();

  final String questionCode;
  final String section;
  final QuestionOption selectedOption;
  final QuestionOption correctOption;
  final DateTime answeredAt;

  bool get isCorrect => selectedOption == correctOption;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuestionAnswerRecord &&
            runtimeType == other.runtimeType &&
            questionCode == other.questionCode &&
            section == other.section &&
            selectedOption == other.selectedOption &&
            correctOption == other.correctOption &&
            answeredAt == other.answeredAt;
  }

  @override
  int get hashCode => Object.hash(
    questionCode,
    section,
    selectedOption,
    correctOption,
    answeredAt,
  );
}
