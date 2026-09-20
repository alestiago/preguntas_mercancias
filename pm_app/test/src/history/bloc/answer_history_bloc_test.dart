import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/history/bloc/answer_history_bloc.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../../fixtures/question_fixtures.dart';
import '../../../helpers/fake_question_progress_store.dart';

void main() {
  test('renders empty history as an explicit state', () async {
    final store = _CountingQuestionProgressStore();
    final bloc = AnswerHistoryBloc(
      questionProgressStore: store,
      catalog: QuestionCatalog(buildQuestions()),
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
      catalog: QuestionCatalog(questions),
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

  test('groups UTC answer instants by their local calendar date', () async {
    final store = _CountingQuestionProgressStore();
    final question = buildQuestions().first;
    final answeredAt = DateTime.utc(2026, 8, 2, 23, 30);
    final localAnswerTime = answeredAt.toLocal();
    await store.recordAnswer(
      QuestionAnswerRecord(
        questionCode: question.code,
        section: question.section,
        selectedOption: QuestionOption.b,
        correctOption: question.correctOption,
        answeredAt: answeredAt,
      ),
    );
    final bloc = AnswerHistoryBloc(
      questionProgressStore: store,
      catalog: QuestionCatalog([question]),
    );
    addTearDown(() async {
      await bloc.close();
      await store.close();
    });

    await _waitUntil(() => bloc.state is AnswerHistoryLoaded);
    final section = (bloc.state as AnswerHistoryLoaded).sections.single;

    expect(
      section.date,
      DateTime(
        localAnswerTime.year,
        localAnswerTime.month,
        localAnswerTime.day,
      ),
    );
  });

  test('surfaces history observation failures', () async {
    final store = _CountingQuestionProgressStore();
    final bloc = AnswerHistoryBloc(
      questionProgressStore: store,
      catalog: QuestionCatalog(buildQuestions()),
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

  test('retry replaces the bounded history subscription', () async {
    final store = _CountingQuestionProgressStore();
    final bloc = AnswerHistoryBloc(
      questionProgressStore: store,
      catalog: QuestionCatalog(buildQuestions()),
    );
    addTearDown(() async {
      await bloc.close();
      await store.close();
    });
    await _waitUntil(() => bloc.state is AnswerHistoryEmpty);

    store.emitSnapshotError(StateError('History failed.'));
    await _waitUntil(() => bloc.state is AnswerHistoryFailure);

    bloc.add(const AnswerHistoryRetried());
    await _waitUntil(() => bloc.state is AnswerHistoryEmpty);

    expect(store.watchAnswerHistoryCallCount, 2);
    expect(store.watchLimits, [100, 100]);
    expect(store.loadLimits, [100, 100]);
  });

  test('initializes from the history watch without an explicit read', () async {
    final store = _WatchOnlyHistoryStore();
    final bloc = AnswerHistoryBloc(
      questionProgressStore: store,
      catalog: QuestionCatalog(buildQuestions()),
    );
    addTearDown(() async {
      await bloc.close();
      await store.close();
    });

    await _waitUntil(() => bloc.state is AnswerHistoryEmpty);

    expect(bloc.state, const AnswerHistoryEmpty());
  });

  test('loads older history by expanding the bounded prefix', () async {
    final store = _CountingQuestionProgressStore();
    final questions = buildQuestions();
    for (var index = 0; index < 3; index += 1) {
      await store.recordAnswer(
        QuestionAnswerRecord(
          questionCode: questions[index % questions.length].code,
          section: '1A',
          selectedOption: QuestionOption.a,
          correctOption: QuestionOption.b,
          answeredAt: DateTime(2026, 8, 1, 10 + index),
        ),
      );
    }
    final bloc = AnswerHistoryBloc(
      questionProgressStore: store,
      catalog: QuestionCatalog(questions),
      pageSize: 1,
    );
    addTearDown(() async {
      await bloc.close();
      await store.close();
    });

    await _waitUntil(
      () =>
          bloc.state is AnswerHistoryLoaded &&
          _entryCount(bloc.state as AnswerHistoryLoaded) == 1,
    );
    expect((bloc.state as AnswerHistoryLoaded).hasMore, isTrue);

    bloc.add(const AnswerHistoryMoreRequested());
    await _waitUntil(
      () =>
          bloc.state is AnswerHistoryLoaded &&
          _entryCount(bloc.state as AnswerHistoryLoaded) == 2,
    );

    final loaded = bloc.state as AnswerHistoryLoaded;
    expect(loaded.hasMore, isTrue);
    expect(loaded.isLoadingMore, isFalse);
    expect(store.watchLimits, [1, 2]);
    expect(store.loadLimits, [1, 2]);
  });

  test(
    'latest observation starts before delayed cancellation cleanup completes',
    () async {
      final store = _ControlledHistoryWatchStore();
      final questions = buildQuestions();
      final bloc = AnswerHistoryBloc(
        questionProgressStore: store,
        catalog: QuestionCatalog(questions),
        pageSize: 1,
      );

      await _waitUntil(() => store.watches.length == 1);
      final firstWatch = store.watches.single;
      firstWatch.add(_historyPage(questions: [questions.first], hasMore: true));
      await _waitUntil(() => bloc.state is AnswerHistoryLoaded);

      bloc.add(const AnswerHistoryMoreRequested());
      await _waitUntil(() => firstWatch.cancellationStarted.isCompleted);
      await _waitUntil(() => store.watches.length == 2);

      expect(firstWatch.allowCancellation.isCompleted, isFalse);
      expect(store.activeWatchCount, 1);
      expect(store.watches.map((watch) => watch.limit), [1, 2]);

      final secondWatch = store.watches.last;
      secondWatch.add(_historyPage(questions: questions, hasMore: false));
      await _waitUntil(
        () =>
            bloc.state is AnswerHistoryLoaded &&
            _entryCount(bloc.state as AnswerHistoryLoaded) == 2,
      );

      firstWatch.add(
        QuestionAnswerHistoryPage(answers: const [], hasMore: false),
      );
      await Future<void>.delayed(Duration.zero);
      expect(_entryCount(bloc.state as AnswerHistoryLoaded), 2);

      firstWatch.allowCancellation.complete();
      secondWatch.allowCancellation.complete();
      await bloc.close();

      expect(secondWatch.cancellationStarted.isCompleted, isTrue);
      expect(store.activeWatchCount, 0);
      await store.close();
    },
  );
}

QuestionAnswerHistoryPage _historyPage({
  required Iterable<Question> questions,
  required bool hasMore,
}) {
  return QuestionAnswerHistoryPage(
    answers: [
      for (final question in questions)
        QuestionAnswerRecord(
          questionCode: question.code,
          section: question.section,
          selectedOption: QuestionOption.a,
          correctOption: question.correctOption,
        ),
    ],
    hasMore: hasMore,
  );
}

final class _WatchOnlyHistoryStore extends FakeQuestionProgressStore {
  @override
  Future<QuestionAnswerHistoryPage> loadAnswerHistory({required int limit}) {
    throw StateError('AnswerHistoryBloc must initialize from the watch.');
  }

  @override
  Stream<QuestionAnswerHistoryPage> watchAnswerHistory({required int limit}) {
    return Stream.value(
      QuestionAnswerHistoryPage(answers: const [], hasMore: false),
    );
  }
}

final class _ControlledHistoryWatchStore extends FakeQuestionProgressStore {
  final List<_ControlledHistoryWatch> watches = [];
  int activeWatchCount = 0;

  @override
  Stream<QuestionAnswerHistoryPage> watchAnswerHistory({required int limit}) {
    late final _ControlledHistoryWatch watch;
    late final StreamController<QuestionAnswerHistoryPage> controller;
    controller = StreamController<QuestionAnswerHistoryPage>(
      onListen: () {
        activeWatchCount += 1;
      },
      onCancel: () {
        activeWatchCount -= 1;
        watch.cancellationStarted.complete();
        return watch.allowCancellation.future;
      },
    );
    watch = _ControlledHistoryWatch(limit: limit, controller: controller);
    watches.add(watch);
    return controller.stream;
  }

  @override
  Future<void> close() async {
    for (final watch in watches) {
      await watch.controller.close();
    }
    await super.close();
  }
}

final class _ControlledHistoryWatch {
  _ControlledHistoryWatch({required this.limit, required this.controller});

  final int limit;
  final StreamController<QuestionAnswerHistoryPage> controller;
  final Completer<void> cancellationStarted = Completer<void>();
  final Completer<void> allowCancellation = Completer<void>();

  void add(QuestionAnswerHistoryPage page) => controller.add(page);
}

int _entryCount(AnswerHistoryLoaded state) {
  return state.sections.fold(
    0,
    (count, section) => count + section.entries.length,
  );
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
  final List<int> watchLimits = [];
  final List<int> loadLimits = [];

  @override
  Stream<QuestionAnswerHistoryPage> watchAnswerHistory({required int limit}) {
    watchAnswerHistoryCallCount += 1;
    watchLimits.add(limit);
    return super.watchAnswerHistory(limit: limit);
  }

  @override
  Future<QuestionAnswerHistoryPage> loadAnswerHistory({required int limit}) {
    loadLimits.add(limit);
    return super.loadAnswerHistory(limit: limit);
  }
}
