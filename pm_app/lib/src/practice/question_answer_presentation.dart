import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:pm_questions/pm_questions.dart';

/// Immutable display order for a question's canonically identified answers.
///
/// [QuestionOption] remains the identity used for selection and persistence;
/// its position in [answers] supplies the temporary label shown to the user.
final class QuestionAnswerPresentation extends Equatable {
  factory QuestionAnswerPresentation.inSourceOrder(Question question) {
    return QuestionAnswerPresentation._(question.answers);
  }

  factory QuestionAnswerPresentation.forSession(
    Question question, {
    required bool shuffleAnswers,
    required Random random,
  }) {
    if (!shuffleAnswers || !question.shuffleable) {
      return QuestionAnswerPresentation.inSourceOrder(question);
    }

    final answers = List<QuestionAnswer>.of(question.answers);
    if (answers.length < 2) {
      return QuestionAnswerPresentation._(answers);
    }

    final originalCorrectAnswerIndex = answers.indexWhere(
      (answer) => answer.option == question.correctOption,
    );
    answers.shuffle(random);

    // Preserve the established smart-shuffle rule: when a plain shuffle
    // leaves the correct answer in its source position, move it one position
    // forward. This intentionally changes plain List.shuffle's distribution.
    if (originalCorrectAnswerIndex >= 0 &&
        answers[originalCorrectAnswerIndex].option == question.correctOption) {
      final swapIndex = (originalCorrectAnswerIndex + 1) % answers.length;
      final swappedAnswer = answers[swapIndex];
      answers[swapIndex] = answers[originalCorrectAnswerIndex];
      answers[originalCorrectAnswerIndex] = swappedAnswer;
    }

    return QuestionAnswerPresentation._(answers);
  }

  QuestionAnswerPresentation._(Iterable<QuestionAnswer> answers)
    : answers = List.unmodifiable(answers),
      _displayIndexByOption = _indexAnswersByOption(answers);

  final List<QuestionAnswer> answers;
  final Map<QuestionOption, int> _displayIndexByOption;

  /// Returns the positional label for a canonical option identity.
  ///
  /// Invalid presentation data fails explicitly instead of silently changing
  /// canonical identity.
  QuestionOption displayOptionFor(QuestionOption option) {
    final index = _displayIndexByOption[option];
    if (index == null || index >= QuestionOption.values.length) {
      throw StateError(
        'Question answer presentation does not support option ${option.code}.',
      );
    }
    return QuestionOption.values[index];
  }

  @override
  List<Object?> get props => [QuestionAnswerPresentation, answers];
}

Map<QuestionOption, int> _indexAnswersByOption(
  Iterable<QuestionAnswer> answers,
) {
  final indexByOption = <QuestionOption, int>{};
  var index = 0;
  for (final answer in answers) {
    if (indexByOption.containsKey(answer.option)) {
      throw ArgumentError.value(
        answers,
        'answers',
        'Canonical answer identities must be unique.',
      );
    }
    indexByOption[answer.option] = index;
    index += 1;
  }
  return Map.unmodifiable(indexByOption);
}
