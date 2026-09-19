// ignore_for_file: avoid_print

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_persistence/src/database/pm_persistence_database.dart';

const _attemptCount = 50000;
const _pageSize = 100;
const _measurementRuns = 15;

void main() {
  test('R26 bounded history benchmark', _runBenchmark);
}

Future<void> _runBenchmark() async {
  final database = PmPersistenceDatabase(NativeDatabase.memory());
  try {
    final startedAt = DateTime.utc(2026);
    await database.batch((batch) {
      batch.insertAll(
        database.questionAttemptRecords,
        List.generate(
          _attemptCount,
          (index) => QuestionAttemptRecordsCompanion.insert(
            questionCode: 'Q${index.toString().padLeft(6, '0')}',
            section: '1A',
            selectedOption: 'A',
            correctOption: 'B',
            isCorrect: false,
            answeredAt: startedAt.add(Duration(seconds: index ~/ 2)),
          ),
          growable: false,
        ),
      );
    });

    await _readHistory(database);
    await _readHistory(database, limit: _pageSize + 1);

    final unbounded = await _medianMicros(() => _readHistory(database));
    final bounded = await _medianMicros(
      () => _readHistory(database, limit: _pageSize + 1),
    );

    print('attempts=$_attemptCount pageSize=$_pageSize');
    print('unboundedMedianMicros=$unbounded');
    print('boundedMedianMicros=$bounded');
    print('speedup=${(unbounded / bounded).toStringAsFixed(1)}x');
  } finally {
    await database.close();
  }
}

Future<int> _readHistory(PmPersistenceDatabase database, {int? limit}) async {
  final select = database.select(database.questionAttemptRecords)
    ..orderBy([
      (record) =>
          OrderingTerm(expression: record.answeredAt, mode: OrderingMode.desc),
      (record) => OrderingTerm(expression: record.id, mode: OrderingMode.desc),
    ]);
  if (limit != null) {
    select.limit(limit);
  }
  return (await select.get()).length;
}

Future<int> _medianMicros(Future<int> Function() operation) async {
  final measurements = <int>[];
  var rowsRead = 0;
  for (var run = 0; run < _measurementRuns; run += 1) {
    final stopwatch = Stopwatch()..start();
    rowsRead += await operation();
    stopwatch.stop();
    measurements.add(stopwatch.elapsedMicroseconds);
  }
  if (rowsRead == 0) {
    throw StateError('The benchmark query returned no rows.');
  }
  measurements.sort();
  return measurements[measurements.length ~/ 2];
}
