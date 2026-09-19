import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/history/bloc/answer_history_bloc.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../../fixtures/question_fixtures.dart';
import '../../../helpers/fake_question_progress_store.dart';

void main() {
  test('renders empty history as an explicit state', () async {
    final store = _CountingQuestionProgressStore();
    final bloc = AnswerHistoryBloc(
      questionProgressStore: store,
      questions: buildQuestions(),
    );
    addTearDown(() async {
      await bloc.close();
      await store.close();
    });

    await _waitUntil(() => bloc.state is AnswerHistoryEmpty);

    expect(bloc.state, const AnswerHistoryEmpty());
    expect(store.watchAnswerHistoryCallCount, 1);
  });

  test('groups recent answers and retains missing questions', () async {
    final store = _CountingQuestionProgressStore();
    final questions = buildQuestions();
    await store.recordAnswer(
      QuestionAnswerRecord(
        questionCode: questions.first.code,
        section: questions.first.section,
        selectedOption: QuestionOption.b,
        correctOption: QuestionOption.b,
        answeredAt: DateTime(2026, 8, 1, 10),
      ),
    );
    await store.recordAnswer(
      QuestionAnswerRecord(
        questionCode: 'missing',
        section: '1A',
        selectedOption: QuestionOption.c,
        correctOption: QuestionOption.a,
        answeredAt: DateTime(2026, 8, 2, 11),
      ),
    );
    final bloc = AnswerHistoryBloc(
      questionProgressStore: store,
      questions: questions,
    );
    addTearDown(() async {
      await bloc.close();
      await store.close();
    });

    await _waitUntil(() => bloc.state is AnswerHistoryLoaded);
    final loaded = bloc.state as AnswerHistoryLoaded;

    expect(loaded.sections, hasLength(2));
    expect(loaded.sections.first.date, DateTime(2026, 8, 2));
    expect(loaded.sections.first.entries.single.question, isNull);
    expect(loaded.sections.last.entries.single.question, questions.first);
    expect(store.watchAnswerHistoryCallCount, 1);
  });

  test('surfaces history observation failures', () async {
    final store = _CountingQuestionProgressStore();
    final bloc = AnswerHistoryBloc(
      questionProgressStore: store,
      questions: buildQuestions(),
    );
    addTearDown(() async {
      await bloc.close();
      await store.close();
    });
    await _waitUntil(() => bloc.state is AnswerHistoryEmpty);

    final error = StateError('History failed.');
    store.emitSnapshotError(error);
    await _waitUntil(() => bloc.state is AnswerHistoryFailure);

    expect((bloc.state as AnswerHistoryFailure).error, error);
  });
}

Future<void> _waitUntil(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TestFailure('Timed out waiting for a test condition.');
    }
    await Future<void>.delayed(Duration.zero);
  }
}

final class _CountingQuestionProgressStore extends FakeQuestionProgressStore {
  int watchAnswerHistoryCallCount = 0;

  @override
  Stream<List<QuestionAnswerRecord>> watchAnswerHistory() {
    watchAnswerHistoryCallCount += 1;
    return super.watchAnswerHistory();
  }
}
