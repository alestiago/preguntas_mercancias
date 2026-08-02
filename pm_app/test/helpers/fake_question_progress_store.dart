import 'dart:async';

import 'package:pm_persistence/pm_persistence.dart';

class FakeQuestionProgressStore implements QuestionProgressStore {
  final Map<String, QuestionProgress> _progressByQuestionCode = {};
  final StreamController<QuestionProgressSnapshot> _controller =
      StreamController<QuestionProgressSnapshot>.broadcast();

  final List<QuestionAnswerRecord> recordedAnswers = [];

  @override
  Future<QuestionProgressSnapshot> loadSnapshot() async {
    return _snapshot;
  }

  @override
  Stream<QuestionProgressSnapshot> watchSnapshot() {
    return _controller.stream;
  }

  @override
  Future<List<QuestionAnswerRecord>> loadAnswerHistory() async {
    final answers = List<QuestionAnswerRecord>.of(recordedAnswers);
    answers.sort((a, b) => b.answeredAt.compareTo(a.answeredAt));
    return List.unmodifiable(answers);
  }

  @override
  Stream<List<QuestionAnswerRecord>> watchAnswerHistory() async* {
    yield await loadAnswerHistory();
    yield* _controller.stream.asyncMap((_) => loadAnswerHistory());
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

  @override
  Future<void> close() {
    return _controller.close();
  }

  QuestionProgressSnapshot get _snapshot {
    return QuestionProgressSnapshot(byQuestionCode: _progressByQuestionCode);
  }
}
