import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/home/bloc/home_bloc.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../../helpers/fake_question_progress_store.dart';

void main() {
  group('HomeBloc', () {
    test(
      'loads overall progress counts from the question bank and store',
      () async {
        final progressStore = FakeQuestionProgressStore();
        addTearDown(progressStore.close);
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

        final bloc = HomeBloc(
          loadQuestions: (_) async => _questions,
          questionProgressStore: progressStore,
        );
        addTearDown(bloc.close);

        final loadedFuture = bloc.stream.firstWhere(
          (state) => state is HomeLoaded,
        );
        bloc.add(const HomeStarted());
        final loaded = await loadedFuture as HomeLoaded;

        expect(loaded.totalQuestionCount, 3);
        expect(loaded.correctQuestionCount, 1);
        expect(loaded.incorrectQuestionCount, 1);
        expect(loaded.unansweredQuestionCount, 1);
      },
    );

    test('refreshes progress without reloading questions', () async {
      var loadCount = 0;
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = HomeBloc(
        loadQuestions: (_) async {
          loadCount += 1;
          return _questions;
        },
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = bloc.stream.firstWhere(
        (state) => state is HomeLoaded,
      );
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

      final refreshedFuture = bloc.stream.firstWhere(
        (state) =>
            state is HomeLoaded && state.progressSnapshot.totalAttempts == 2,
      );
      bloc.add(const HomeProgressRefreshed());
      final refreshed = await refreshedFuture as HomeLoaded;

      expect(loadCount, 1);
      expect(refreshed.totalQuestionCount, 3);
      expect(refreshed.correctQuestionCount, 1);
      expect(refreshed.incorrectQuestionCount, 1);
      expect(refreshed.unansweredQuestionCount, 1);
    });

    test('updates when progress changes without a manual refresh', () async {
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = HomeBloc(
        loadQuestions: (_) async => _questions,
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = bloc.stream.firstWhere(
        (state) => state is HomeLoaded,
      );
      bloc.add(const HomeStarted());
      await loadedFuture;

      final updatedFuture = bloc.stream.firstWhere(
        (state) =>
            state is HomeLoaded && state.progressSnapshot.totalAttempts == 1,
      );
      await progressStore.recordAnswer(
        QuestionAnswerRecord(
          questionCode: '1A01001',
          section: '1A',
          selectedOption: QuestionOption.b,
          correctOption: QuestionOption.b,
        ),
      );
      final updated = await updatedFuture as HomeLoaded;

      expect(updated.correctQuestionCount, 1);
      expect(updated.incorrectQuestionCount, 0);
      expect(updated.unansweredQuestionCount, 2);
    });

    test('keeps a question correct after a later incorrect attempt', () async {
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
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

      final bloc = HomeBloc(
        loadQuestions: (_) async => _questions,
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = bloc.stream.firstWhere(
        (state) => state is HomeLoaded,
      );
      bloc.add(const HomeStarted());
      final loaded = await loadedFuture as HomeLoaded;

      expect(loaded.correctQuestionCount, 1);
      expect(loaded.incorrectQuestionCount, 0);
      expect(loaded.unansweredQuestionCount, 2);
    });
  });
}

final _questions = [
  Question(
    code: '1A01001',
    section: '1A',
    prompt: 'Primera pregunta',
    answers: const [
      QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
      QuestionAnswer(option: QuestionOption.b, text: 'Respuesta B'),
      QuestionAnswer(option: QuestionOption.c, text: 'Respuesta C'),
      QuestionAnswer(option: QuestionOption.d, text: 'Respuesta D'),
    ],
    correctOption: QuestionOption.b,
    norma: 'Norma primera',
  ),
  Question(
    code: '1A01002',
    section: '1A',
    prompt: 'Segunda pregunta',
    answers: const [
      QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
      QuestionAnswer(option: QuestionOption.b, text: 'Respuesta B'),
      QuestionAnswer(option: QuestionOption.c, text: 'Respuesta C'),
      QuestionAnswer(option: QuestionOption.d, text: 'Respuesta D'),
    ],
    correctOption: QuestionOption.a,
    norma: 'Norma segunda',
  ),
  Question(
    code: '1A01003',
    section: '1A',
    prompt: 'Tercera pregunta',
    answers: const [
      QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
      QuestionAnswer(option: QuestionOption.b, text: 'Respuesta B'),
      QuestionAnswer(option: QuestionOption.c, text: 'Respuesta C'),
      QuestionAnswer(option: QuestionOption.d, text: 'Respuesta D'),
    ],
    correctOption: QuestionOption.d,
    norma: 'Norma tercera',
  ),
];
