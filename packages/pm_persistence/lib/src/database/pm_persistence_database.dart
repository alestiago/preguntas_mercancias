import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'pm_persistence_database.g.dart';

class QuestionProgressRecords extends Table {
  TextColumn get questionCode => text()();
  TextColumn get section => text()();
  TextColumn get lastSelectedOption => text().withLength(min: 1, max: 1)();
  TextColumn get correctOption => text().withLength(min: 1, max: 1)();
  BoolColumn get lastAnswerWasCorrect => boolean()();
  IntColumn get attempts => integer()();
  IntColumn get correctAttempts => integer()();
  IntColumn get incorrectAttempts => integer()();
  DateTimeColumn get firstAnsweredAt => dateTime()();
  DateTimeColumn get lastAnsweredAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {questionCode};
}

class QuestionAttemptRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get questionCode => text()();
  TextColumn get section => text()();
  TextColumn get selectedOption => text().withLength(min: 1, max: 1)();
  TextColumn get correctOption => text().withLength(min: 1, max: 1)();
  BoolColumn get isCorrect => boolean()();
  DateTimeColumn get answeredAt => dateTime()();
}

@DriftDatabase(tables: [QuestionProgressRecords, QuestionAttemptRecords])
final class PmPersistenceDatabase extends _$PmPersistenceDatabase {
  PmPersistenceDatabase(super.executor);

  PmPersistenceDatabase.defaults()
    : super(
        driftDatabase(
          name: 'pm_persistence',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  @override
  int get schemaVersion => 1;
}
