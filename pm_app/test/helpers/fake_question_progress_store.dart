import 'dart:async';

import 'package:pm_persistence/pm_persistence.dart';

class FakeQuestionProgressStore implements QuestionProgressStore {
  final Map<String, QuestionProgress> _progressByQuestionCode = {};
  final StreamController<QuestionProgressSnapshot> _controller =
      StreamController<QuestionProgressSnapshot>.broadcast();

  final List<QuestionAnswerRecord> recordedAnswers = [];
  int closeCallCount = 0;

  @override
  Future<QuestionProgressSnapshot> loadSnapshot() async {
    return _snapshot;
  }

  @override
  Stream<QuestionProgressSnapshot> watchSnapshot() async* {
    yield _snapshot;
    yield* _controller.stream;
  }

  @override
  Future<QuestionAnswerHistoryPage> loadAnswerHistory({
    required int limit,
  }) async {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'must be greater than zero');
    }

    final indexedAnswers = recordedAnswers.indexed.toList(growable: false)
      ..sort((a, b) {
        final timestampOrder = b.$2.answeredAt.compareTo(a.$2.answeredAt);
        return timestampOrder != 0 ? timestampOrder : b.$1.compareTo(a.$1);
      });
    return QuestionAnswerHistoryPage(
      answers: indexedAnswers.take(limit).map((entry) => entry.$2),
      hasMore: indexedAnswers.length > limit,
    );
  }

  @override
  Stream<QuestionAnswerHistoryPage> watchAnswerHistory({
    required int limit,
  }) async* {
    yield await loadAnswerHistory(limit: limit);
    yield* _controller.stream.asyncMap((_) => loadAnswerHistory(limit: limit));
  }

  @override
  Future<void> recordAnswer(QuestionAnswerRecord answer) async {
    recordedAnswers.add(answer);

    final existing = _progressByQuestionCode[answer.questionCode];
    if (existing == null) {
      _progressByQuestionCode[answer.questionCode] = QuestionProgress(
        questionCode: answer.questionCode,
        section: answer.section,
        lastSelectedOption: answer.selectedOption,
        correctOption: answer.correctOption,
        lastAnswerWasCorrect: answer.isCorrect,
        attempts: 1,
        correctAttempts: answer.isCorrect ? 1 : 0,
        incorrectAttempts: answer.isCorrect ? 0 : 1,
        firstAnsweredAt: answer.answeredAt,
        lastAnsweredAt: answer.answeredAt,
      );
    } else {
      _progressByQuestionCode[answer.questionCode] = QuestionProgress(
        questionCode: answer.questionCode,
        section: answer.section,
        lastSelectedOption: answer.selectedOption,
        correctOption: answer.correctOption,
        lastAnswerWasCorrect: answer.isCorrect,
        attempts: existing.attempts + 1,
        correctAttempts: existing.correctAttempts + (answer.isCorrect ? 1 : 0),
        incorrectAttempts:
            existing.incorrectAttempts + (answer.isCorrect ? 0 : 1),
        firstAnsweredAt: existing.firstAnsweredAt,
        lastAnsweredAt: answer.answeredAt,
      );
    }

    _controller.add(_snapshot);
  }

  @override
  Future<void> clear() async {
    recordedAnswers.clear();
    _progressByQuestionCode.clear();
    _controller.add(_snapshot);
  }

  void emitSnapshotError(Object error, [StackTrace? stackTrace]) {
    _controller.addError(error, stackTrace);
  }

  @override
  Future<void> close() {
    closeCallCount += 1;
    return _controller.close();
  }

  QuestionProgressSnapshot get _snapshot {
    return QuestionProgressSnapshot(byQuestionCode: _progressByQuestionCode);
  }
}
