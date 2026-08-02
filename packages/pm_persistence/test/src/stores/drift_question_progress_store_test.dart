import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

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
  });
}
