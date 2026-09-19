import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/home/bloc/home_bloc.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

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

      final refreshedFuture = _waitForLoaded(
        bloc,
        (state) => state.progressSnapshot.totalAttempts == 2,
      );
      bloc.add(const HomeProgressRefreshed());
      final refreshed = await refreshedFuture;

      expect(loadCount, 1);
      expect(refreshed.totalQuestionCount, 3);
      expect(refreshed.correctQuestionCount, 1);
      expect(refreshed.incorrectQuestionCount, 1);
      expect(refreshed.unansweredQuestionCount, 1);
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
