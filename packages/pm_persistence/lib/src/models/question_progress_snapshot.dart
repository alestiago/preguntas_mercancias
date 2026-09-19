import 'package:equatable/equatable.dart';

import 'question_progress.dart';

final class QuestionProgressSnapshot extends Equatable {
  const QuestionProgressSnapshot.empty() : byQuestionCode = const {};

  QuestionProgressSnapshot({
    required Map<String, QuestionProgress> byQuestionCode,
  }) : byQuestionCode = Map.unmodifiable(byQuestionCode);

  final Map<String, QuestionProgress> byQuestionCode;

  int get answeredQuestionCount => byQuestionCode.length;

  int get totalAttempts {
    return byQuestionCode.values.fold(
      0,
      (total, progress) => total + progress.attempts,
    );
  }

  int get correctAttempts {
    return byQuestionCode.values.fold(
      0,
      (total, progress) => total + progress.correctAttempts,
    );
  }

  int get incorrectAttempts {
    return byQuestionCode.values.fold(
      0,
      (total, progress) => total + progress.incorrectAttempts,
    );
  }

  QuestionProgress? progressFor(String questionCode) {
    return byQuestionCode[questionCode];
  }

  @override
  List<Object?> get props => [QuestionProgressSnapshot, byQuestionCode];
}
