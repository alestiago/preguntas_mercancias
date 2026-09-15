import 'package:collection/collection.dart';

import 'question.dart';

const _questionListEquality = ListEquality<Question>();
const _selectedOptionsMapEquality = MapEquality<String, QuestionOption>();

/// A snapshot of the results of a completed practice session (e.g. a
/// "Simulacro"), used to render a summary once every question has been
/// answered.
final class PracticeSummary {
  const PracticeSummary({
    required this.questions,
    required this.selectedOptionsByQuestionCode,
    required this.correctCount,
    required this.incorrectCount,
    required this.elapsedTime,
  });

  final List<Question> questions;
  final Map<String, QuestionOption> selectedOptionsByQuestionCode;
  final int correctCount;
  final int incorrectCount;
  final Duration elapsedTime;

  int get totalCount => questions.length;

  double get scoreRatio => totalCount == 0 ? 0 : correctCount / totalCount;

  QuestionOption? selectedOptionFor(Question question) =>
      selectedOptionsByQuestionCode[question.code];

  bool isCorrect(Question question) {
    final selectedOption = selectedOptionFor(question);
    return selectedOption != null && question.isCorrect(selectedOption);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PracticeSummary &&
            runtimeType == other.runtimeType &&
            _questionListEquality.equals(questions, other.questions) &&
            _selectedOptionsMapEquality.equals(
              selectedOptionsByQuestionCode,
              other.selectedOptionsByQuestionCode,
            ) &&
            correctCount == other.correctCount &&
            incorrectCount == other.incorrectCount &&
            elapsedTime == other.elapsedTime;
  }

  @override
  int get hashCode => Object.hash(
    _questionListEquality.hash(questions),
    _selectedOptionsMapEquality.hash(selectedOptionsByQuestionCode),
    correctCount,
    incorrectCount,
    elapsedTime,
  );
}
