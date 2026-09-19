import 'package:drift/drift.dart';
import 'package:pm_questions/pm_questions.dart';

import '../database/pm_persistence_database.dart';
import '../models/models.dart';
import 'question_progress_store.dart';

final class DriftQuestionProgressStore implements QuestionProgressStore {
  DriftQuestionProgressStore(this._database);

  factory DriftQuestionProgressStore.defaults() {
    return DriftQuestionProgressStore(PmPersistenceDatabase.defaults());
  }

  final PmPersistenceDatabase _database;

  @override
  Future<QuestionProgressSnapshot> loadSnapshot() async {
    final rows = await _database
        .select(_database.questionProgressRecords)
        .get();
    return _snapshotFromRows(rows);
  }

  @override
  Stream<QuestionProgressSnapshot> watchSnapshot() {
    return _database
        .select(_database.questionProgressRecords)
        .watch()
        .map(_snapshotFromRows);
  }

  @override
  Future<List<QuestionAnswerRecord>> loadAnswerHistory() async {
    final rows = await _answerHistorySelect().get();
    return _answerHistoryFromRows(rows);
  }

  @override
  Stream<List<QuestionAnswerRecord>> watchAnswerHistory() {
    return _answerHistorySelect().watch().map(_answerHistoryFromRows);
  }

  @override
  Future<void> recordAnswer(QuestionAnswerRecord answer) {
    return _database.transaction(() async {
      await _database
          .into(_database.questionAttemptRecords)
          .insert(_attemptCompanionFor(answer));

      final existing =
          await (_database.select(_database.questionProgressRecords)..where(
                (record) => record.questionCode.equals(answer.questionCode),
              ))
              .getSingleOrNull();

      if (existing == null) {
        await _database
            .into(_database.questionProgressRecords)
            .insert(_newProgressCompanionFor(answer));
        return;
      }

      await (_database.update(
            _database.questionProgressRecords,
          )..where((record) => record.questionCode.equals(answer.questionCode)))
          .write(_updatedProgressCompanionFor(existing, answer));
    });
  }

  @override
  Future<void> clear() {
    return _database.transaction(() async {
      await _database.delete(_database.questionAttemptRecords).go();
      await _database.delete(_database.questionProgressRecords).go();
    });
  }

  @override
  Future<void> close() {
    return _database.close();
  }

  SimpleSelectStatement<$QuestionAttemptRecordsTable, QuestionAttemptRecord>
  _answerHistorySelect() {
    return _database.select(_database.questionAttemptRecords)..orderBy([
      (record) =>
          OrderingTerm(expression: record.answeredAt, mode: OrderingMode.desc),
      (record) => OrderingTerm(expression: record.id, mode: OrderingMode.desc),
    ]);
  }
}

QuestionAttemptRecordsCompanion _attemptCompanionFor(
  QuestionAnswerRecord answer,
) {
  return QuestionAttemptRecordsCompanion.insert(
    questionCode: answer.questionCode,
    section: answer.section,
    selectedOption: answer.selectedOption.code,
    correctOption: answer.correctOption.code,
    isCorrect: answer.isCorrect,
    answeredAt: answer.answeredAt,
  );
}

QuestionProgressRecordsCompanion _newProgressCompanionFor(
  QuestionAnswerRecord answer,
) {
  return QuestionProgressRecordsCompanion.insert(
    questionCode: answer.questionCode,
    section: answer.section,
    lastSelectedOption: answer.selectedOption.code,
    correctOption: answer.correctOption.code,
    lastAnswerWasCorrect: answer.isCorrect,
    attempts: 1,
    correctAttempts: answer.isCorrect ? 1 : 0,
    incorrectAttempts: answer.isCorrect ? 0 : 1,
    firstAnsweredAt: answer.answeredAt,
    lastAnsweredAt: answer.answeredAt,
  );
}

QuestionProgressRecordsCompanion _updatedProgressCompanionFor(
  QuestionProgressRecord existing,
  QuestionAnswerRecord answer,
) {
  return QuestionProgressRecordsCompanion(
    section: Value(answer.section),
    lastSelectedOption: Value(answer.selectedOption.code),
    correctOption: Value(answer.correctOption.code),
    lastAnswerWasCorrect: Value(answer.isCorrect),
    attempts: Value(existing.attempts + 1),
    correctAttempts: Value(
      existing.correctAttempts + (answer.isCorrect ? 1 : 0),
    ),
    incorrectAttempts: Value(
      existing.incorrectAttempts + (answer.isCorrect ? 0 : 1),
    ),
    lastAnsweredAt: Value(answer.answeredAt),
  );
}

QuestionProgressSnapshot _snapshotFromRows(
  Iterable<QuestionProgressRecord> rows,
) {
  return QuestionProgressSnapshot(
    byQuestionCode: {
      for (final row in rows)
        row.questionCode: QuestionProgress(
          questionCode: row.questionCode,
          section: row.section,
          lastSelectedOption: QuestionOption.fromCode(row.lastSelectedOption),
          correctOption: QuestionOption.fromCode(row.correctOption),
          lastAnswerWasCorrect: row.lastAnswerWasCorrect,
          attempts: row.attempts,
          correctAttempts: row.correctAttempts,
          incorrectAttempts: row.incorrectAttempts,
          firstAnsweredAt: row.firstAnsweredAt,
          lastAnsweredAt: row.lastAnsweredAt,
        ),
    },
  );
}

List<QuestionAnswerRecord> _answerHistoryFromRows(
  Iterable<QuestionAttemptRecord> rows,
) {
  return List<QuestionAnswerRecord>.unmodifiable(
    rows.map(
      (row) => QuestionAnswerRecord(
        questionCode: row.questionCode,
        section: row.section,
        selectedOption: QuestionOption.fromCode(row.selectedOption),
        correctOption: QuestionOption.fromCode(row.correctOption),
        answeredAt: row.answeredAt,
      ),
    ),
  );
}
