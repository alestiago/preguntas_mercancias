import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_persistence/src/database/pm_persistence_database.dart';
import 'package:pm_questions/pm_questions.dart';

void main() {
  group('DriftQuestionProgressStore', () {
    late PmPersistenceDatabase database;
    late DriftQuestionProgressStore store;

    setUp(() {
      database = PmPersistenceDatabase(NativeDatabase.memory());
      store = DriftQuestionProgressStore(database);
    });

    tearDown(() => store.close());

    test('records progress for a question', () async {
      final answeredAt = DateTime(2026, 8);

      await store.recordAnswer(
        QuestionAnswerRecord(
          questionCode: '1A01001',
          section: '1A',
          selectedOption: QuestionOption.b,
          correctOption: QuestionOption.b,
          answeredAt: answeredAt,
        ),
      );

      final snapshot = await store.loadSnapshot();
      final progress = snapshot.progressFor('1A01001');

      expect(snapshot.answeredQuestionCount, 1);
      expect(snapshot.totalAttempts, 1);
      expect(progress?.lastSelectedOption, QuestionOption.b);
      expect(progress?.lastAnswerWasCorrect, isTrue);
      expect(progress?.attempts, 1);
      expect(progress?.correctAttempts, 1);
      expect(progress?.incorrectAttempts, 0);
      expect(progress?.firstAnsweredAt, answeredAt);
      expect(progress?.lastAnsweredAt, answeredAt);
    });

    test('updates aggregate progress on repeated answers', () async {
      await store.recordAnswer(
        QuestionAnswerRecord(
          questionCode: '1A01001',
          section: '1A',
          selectedOption: QuestionOption.a,
          correctOption: QuestionOption.b,
          answeredAt: DateTime(2026, 8),
        ),
      );
      await store.recordAnswer(
        QuestionAnswerRecord(
          questionCode: '1A01001',
          section: '1A',
          selectedOption: QuestionOption.b,
          correctOption: QuestionOption.b,
          answeredAt: DateTime(2026, 8, 1, 1),
        ),
      );

      final progress = (await store.loadSnapshot()).progressFor('1A01001');

      expect(progress?.lastSelectedOption, QuestionOption.b);
      expect(progress?.lastAnswerWasCorrect, isTrue);
      expect(progress?.attempts, 2);
      expect(progress?.correctAttempts, 1);
      expect(progress?.incorrectAttempts, 1);
      expect(progress?.lastAnsweredAt, DateTime(2026, 8, 1, 1));
    });

    test('loads answer history with the most recent answer first', () async {
      await store.recordAnswer(
        QuestionAnswerRecord(
          questionCode: '1A01001',
          section: '1A',
          selectedOption: QuestionOption.a,
          correctOption: QuestionOption.b,
          answeredAt: DateTime(2026, 8, 1, 10),
        ),
      );
      await store.recordAnswer(
        QuestionAnswerRecord(
          questionCode: '1B01001',
          section: '1B',
          selectedOption: QuestionOption.b,
          correctOption: QuestionOption.b,
          answeredAt: DateTime(2026, 8, 1, 11),
        ),
      );

      final history = await store.loadAnswerHistory(limit: 100);

      expect(history.answers.map((answer) => answer.questionCode), [
        '1B01001',
        '1A01001',
      ]);
      expect(history.hasMore, isFalse);
    });

    test(
      'bounds history and orders equal timestamps by newest insert',
      () async {
        final answeredAt = DateTime(2026, 8, 1, 10);
        for (final code in ['1A01001', '1A01002', '1A01003']) {
          await store.recordAnswer(
            QuestionAnswerRecord(
              questionCode: code,
              section: '1A',
              selectedOption: QuestionOption.a,
              correctOption: QuestionOption.b,
              answeredAt: answeredAt,
            ),
          );
        }

        final firstPrefix = await store.loadAnswerHistory(limit: 2);
        final expandedPrefix = await store.loadAnswerHistory(limit: 3);

        expect(firstPrefix.answers.map((answer) => answer.questionCode), [
          '1A01003',
          '1A01002',
        ]);
        expect(firstPrefix.hasMore, isTrue);
        expect(expandedPrefix.answers.map((answer) => answer.questionCode), [
          '1A01003',
          '1A01002',
          '1A01001',
        ]);
        expect(expandedPrefix.hasMore, isFalse);
      },
    );

    test('rejects a non-positive history limit', () async {
      expect(() => store.loadAnswerHistory(limit: 0), throwsArgumentError);
    });

    test('watchSnapshot emits the current value and later writes', () async {
      final snapshotsFuture = store.watchSnapshot().take(2).toList();
      await pumpEventQueue();

      await store.recordAnswer(
        QuestionAnswerRecord(
          questionCode: '1A01001',
          section: '1A',
          selectedOption: QuestionOption.b,
          correctOption: QuestionOption.b,
        ),
      );
      final snapshots = await snapshotsFuture;

      expect(snapshots.first, const QuestionProgressSnapshot.empty());
      expect(snapshots.last.totalAttempts, 1);
    });

    test('late watchSnapshot subscribers receive the current value', () async {
      await store.recordAnswer(
        QuestionAnswerRecord(
          questionCode: '1A01001',
          section: '1A',
          selectedOption: QuestionOption.b,
          correctOption: QuestionOption.b,
        ),
      );

      expect((await store.watchSnapshot().first).totalAttempts, 1);
    });

    test('watchSnapshot observes writes through another store', () async {
      final observingStore = DriftQuestionProgressStore(database);
      final snapshotsFuture = observingStore.watchSnapshot().take(2).toList();
      await pumpEventQueue();

      await store.recordAnswer(
        QuestionAnswerRecord(
          questionCode: '1A01001',
          section: '1A',
          selectedOption: QuestionOption.b,
          correctOption: QuestionOption.b,
        ),
      );
      final snapshots = await snapshotsFuture;

      expect(snapshots.first, const QuestionProgressSnapshot.empty());
      expect(snapshots.last.totalAttempts, 1);
    });

    test('watchAnswerHistory emits current history and later writes', () async {
      final historyFuture = store
          .watchAnswerHistory(limit: 100)
          .take(2)
          .toList();
      await pumpEventQueue();

      await store.recordAnswer(
        QuestionAnswerRecord(
          questionCode: '1A01001',
          section: '1A',
          selectedOption: QuestionOption.b,
          correctOption: QuestionOption.b,
        ),
      );
      final history = await historyFuture;

      expect(history.first.answers, isEmpty);
      expect(history.last.answers.single.questionCode, '1A01001');
    });
  });
}
