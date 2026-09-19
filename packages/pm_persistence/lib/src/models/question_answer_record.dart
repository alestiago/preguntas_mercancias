import 'package:equatable/equatable.dart';
import 'package:pm_questions/pm_questions.dart';

final class QuestionAnswerRecord extends Equatable {
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
  List<Object?> get props => [
    QuestionAnswerRecord,
    questionCode,
    section,
    selectedOption,
    correctOption,
    answeredAt,
  ];
}
