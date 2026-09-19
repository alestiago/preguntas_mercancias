import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/home/bloc/home_bloc.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions/pm_questions.dart';

import '../../../fixtures/question_fixtures.dart';
import '../../../helpers/fake_question_progress_store.dart';

void main() {
  group('HomeBloc', () {
    late FakeQuestionProgressStore progressStore;

    setUp(() {
      progressStore = FakeQuestionProgressStore();
    });

    tearDown(() => progressStore.close());

    blocTest<HomeBloc, HomeState>(
      'loads overall progress counts from the question bank and store',
      setUp: () async {
        await progressStore.recordAnswer(
          QuestionAnswerRecord(
            questionCode: '1A01001',
            section: '1A',
            selectedOption: QuestionOption.b,
            correctOption: QuestionOption.b,
          ),
        );
        await progressStore.recordAnswer(
          QuestionAnswerRecord(
            questionCode: '1A01002',
            section: '1A',
            selectedOption: QuestionOption.c,
            correctOption: QuestionOption.a,
          ),
        );
      },
      build: () => HomeBloc(
        loadQuestions: (_) async => buildHomeQuestions(),
        questionProgressStore: progressStore,
      ),
      act: (bloc) => bloc.add(const HomeStarted()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>()
            .having(
              (state) => state.totalQuestionCount,
              'total question count',
              3,
            )
            .having(
              (state) => state.correctQuestionCount,
              'correct question count',
              1,
            )
            .having(
              (state) => state.incorrectQuestionCount,
              'incorrect question count',
              1,
            )
            .having(
              (state) => state.unansweredQuestionCount,
              'unanswered question count',
              1,
            ),
      ],
    );

    test('refreshes progress without reloading questions', () async {
      var loadCount = 0;
      final bloc = HomeBloc(
        loadQuestions: (_) async {
          loadCount += 1;
          return buildHomeQuestions();
        },
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = _waitForLoaded(bloc);
      bloc.add(const HomeStarted());
      await loadedFuture;

      final refreshedFuture = _waitForLoaded(
        bloc,
        (state) => state.progressSnapshot.totalAttempts == 2,
      );
      await progressStore.recordAnswer(
        QuestionAnswerRecord(
          questionCode: '1A01001',
          section: '1A',
          selectedOption: QuestionOption.b,
          correctOption: QuestionOption.b,
        ),
      );
      await progressStore.recordAnswer(
        QuestionAnswerRecord(
          questionCode: '1A01002',
          section: '1A',
          selectedOption: QuestionOption.c,
          correctOption: QuestionOption.a,
        ),
      );

      final refreshed = await refreshedFuture;

      expect(loadCount, 1);
      expect(refreshed.totalQuestionCount, 3);
      expect(refreshed.correctQuestionCount, 1);
      expect(refreshed.incorrectQuestionCount, 1);
      expect(refreshed.unansweredQuestionCount, 1);
    });

    test('HomeLoaded is defensively immutable and value comparable', () {
      final questions = buildHomeQuestions();
      final state = HomeLoaded(
        questions: questions,
        progressSnapshot: const QuestionProgressSnapshot.empty(),
      );
      final equalState = HomeLoaded(
        questions: buildHomeQuestions(),
        progressSnapshot: const QuestionProgressSnapshot.empty(),
      );

      questions.clear();

      expect(state.questions, hasLength(3));
      expect(() => state.questions.clear(), throwsUnsupportedError);
      expect(state, equalState);
      expect(state.hashCode, equalState.hashCode);
    });

    test('keeps dashboard counts aligned with session selections', () async {
      await progressStore.recordAnswer(
        QuestionAnswerRecord(
          questionCode: '1A01001',
          section: '1A',
          selectedOption: QuestionOption.b,
          correctOption: QuestionOption.b,
        ),
      );
      await progressStore.recordAnswer(
        QuestionAnswerRecord(
          questionCode: '1A01002',
          section: '1A',
          selectedOption: QuestionOption.c,
          correctOption: QuestionOption.a,
        ),
      );
      await progressStore.recordAnswer(
        QuestionAnswerRecord(
          questionCode: '9Z99999',
          section: '9Z',
          selectedOption: QuestionOption.a,
          correctOption: QuestionOption.b,
        ),
      );
      final bloc = HomeBloc(
        loadQuestions: (_) async => buildHomeQuestions(),
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = _waitForLoaded(bloc);
      bloc.add(const HomeStarted());
      final loaded = await loadedFuture;
      final reviewQuestions = await loaded.reviewLoadQuestions()(null);
      final pendingQuestions = await loaded.pendingLoadQuestions(batchSize: 10)(
        null,
      );
      final pendingSession = loaded.pendingSession(shuffleAnswers: false);

      expect(loaded.totalQuestionCount, 3);
      expect(loaded.incorrectQuestionCount, reviewQuestions.length);
      expect(loaded.unansweredQuestionCount, pendingQuestions.length);
      expect(loaded.pendingQuestionCountsBySection, {'1A': 1});
      expect(pendingSession.pendingQuestionCount, pendingQuestions.length);
      expect(pendingSession.pendingQuestionCountsBySection, {'1A': 1});
      expect(pendingSession.shuffleAnswers, isFalse);
      expect(reviewQuestions.map((question) => question.code), ['1A01002']);
      expect(pendingQuestions.map((question) => question.code), ['1A01003']);
    });

    test('updates when progress changes without a manual refresh', () async {
      final bloc = HomeBloc(
        loadQuestions: (_) async => buildHomeQuestions(),
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = _waitForLoaded(bloc);
      bloc.add(const HomeStarted());
      await loadedFuture;

      final updatedFuture = _waitForLoaded(
        bloc,
        (state) => state.progressSnapshot.totalAttempts == 1,
      );
      await progressStore.recordAnswer(
        QuestionAnswerRecord(
          questionCode: '1A01001',
          section: '1A',
          selectedOption: QuestionOption.b,
          correctOption: QuestionOption.b,
        ),
      );
      final updated = await updatedFuture;

      expect(updated.correctQuestionCount, 1);
      expect(updated.incorrectQuestionCount, 0);
      expect(updated.unansweredQuestionCount, 2);
    });

    blocTest<HomeBloc, HomeState>(
      'keeps a question correct after a later incorrect attempt',
      setUp: () async {
        await progressStore.recordAnswer(
          QuestionAnswerRecord(
            questionCode: '1A01001',
            section: '1A',
            selectedOption: QuestionOption.b,
            correctOption: QuestionOption.b,
          ),
        );
        await progressStore.recordAnswer(
          QuestionAnswerRecord(
            questionCode: '1A01001',
            section: '1A',
            selectedOption: QuestionOption.a,
            correctOption: QuestionOption.b,
          ),
        );
      },
      build: () => HomeBloc(
        loadQuestions: (_) async => buildHomeQuestions(),
        questionProgressStore: progressStore,
      ),
      act: (bloc) => bloc.add(const HomeStarted()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>()
            .having(
              (state) => state.correctQuestionCount,
              'correct question count',
              1,
            )
            .having(
              (state) => state.incorrectQuestionCount,
              'incorrect question count',
              0,
            )
            .having(
              (state) => state.unansweredQuestionCount,
              'unanswered question count',
              2,
            ),
      ],
    );

    test('keeps the latest result when reads finish out of order', () async {
      final pendingLoads = <Completer<List<Question>>>[];
      final bloc = HomeBloc(
        loadQuestions: (_) {
          final completer = Completer<List<Question>>();
          pendingLoads.add(completer);
          return completer.future;
        },
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      bloc.add(const HomeStarted());
      await _waitUntil(() => pendingLoads.length == 1);
      bloc.add(const HomeRetried());
      await _waitUntil(() => pendingLoads.length == 2);

      final latestLoadedFuture = _waitForLoaded(
        bloc,
        (state) => state.questions.length == 1,
      );
      pendingLoads[1].complete([buildHomeQuestions().last]);
      final latestLoaded = await latestLoadedFuture;

      pendingLoads[0].complete(buildHomeQuestions());
      await Future<void>.delayed(Duration.zero);

      expect(latestLoaded.questions.single.prompt, 'Tercera pregunta');
      expect((bloc.state as HomeLoaded).questions, hasLength(1));
      expect(
        (bloc.state as HomeLoaded).questions.single.prompt,
        'Tercera pregunta',
      );
    });

    test('initializes progress from the watch stream only', () async {
      final watchOnlyStore = _WatchOnlyQuestionProgressStore();
      addTearDown(watchOnlyStore.close);
      final bloc = HomeBloc(
        loadQuestions: (_) async => buildHomeQuestions(),
        questionProgressStore: watchOnlyStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = _waitForLoaded(bloc);
      bloc.add(const HomeStarted());
      final loaded = await loadedFuture;

      expect(loaded.progressSnapshot, const QuestionProgressSnapshot.empty());
    });

    test('surfaces progress observation errors', () async {
      final bloc = HomeBloc(
        loadQuestions: (_) async => buildHomeQuestions(),
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);
      final loadedFuture = _waitForLoaded(bloc);
      bloc.add(const HomeStarted());
      await loadedFuture;

      final failureFuture = bloc.stream
          .where((state) => state is HomeLoadFailure)
          .cast<HomeLoadFailure>()
          .first
          .timeout(const Duration(seconds: 2));
      final error = StateError('Progress watch failed.');
      progressStore.emitSnapshotError(error);

      expect((await failureFuture).error, error);
    });

    test('cancels progress observation when closed', () async {
      final bloc = HomeBloc(
        loadQuestions: (_) async => buildHomeQuestions(),
        questionProgressStore: progressStore,
      );
      final loadedFuture = _waitForLoaded(bloc);
      bloc.add(const HomeStarted());
      final loaded = await loadedFuture;

      await bloc.close();
      await progressStore.recordAnswer(
        QuestionAnswerRecord(
          questionCode: '1A01001',
          section: '1A',
          selectedOption: QuestionOption.b,
          correctOption: QuestionOption.b,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state, loaded);
    });
  });
}

Future<HomeLoaded> _waitForLoaded(
  HomeBloc bloc, [
  bool Function(HomeLoaded state)? predicate,
]) {
  return bloc.stream
      .where((state) => state is HomeLoaded)
      .cast<HomeLoaded>()
      .firstWhere(predicate ?? (_) => true)
      .timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TestFailure(
          'Timed out waiting for HomeLoaded; current state: ${bloc.state}',
        ),
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

final class _WatchOnlyQuestionProgressStore extends FakeQuestionProgressStore {
  @override
  Future<QuestionProgressSnapshot> loadSnapshot() {
    throw StateError('HomeBloc must initialize from watchSnapshot().');
  }
}
