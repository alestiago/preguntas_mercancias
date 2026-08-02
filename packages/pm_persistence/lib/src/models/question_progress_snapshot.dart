import 'package:collection/collection.dart';

import 'question_progress.dart';

const _progressMapEquality = MapEquality<String, QuestionProgress>();

final class QuestionProgressSnapshot {
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
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuestionProgressSnapshot &&
            runtimeType == other.runtimeType &&
            _progressMapEquality.equals(byQuestionCode, other.byQuestionCode);
  }

  @override
  int get hashCode => _progressMapEquality.hash(byQuestionCode);
}
