import 'dart:async';
import 'dart:math';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice/bloc/practice_bloc.dart';
import 'package:pm_app/src/practice/practice_session_config.dart';
import 'package:pm_app/src/questions/pending_question_batch.dart';
import 'package:pm_persistence/pm_persistence.dart';
import 'package:pm_questions_bank/pm_questions_bank.dart';

import '../../../fixtures/question_fixtures.dart';
import '../../../helpers/fake_question_progress_store.dart';

void main() {
  group('PracticeBloc', () {
    late FakeQuestionProgressStore noOpProgressStore;

    test('loads questions and records an answer', () async {
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => buildQuestions(),
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = _waitForPracticeState(
        bloc,
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      final loaded = await loadedFuture as PracticeLoaded;

      expect(loaded.questions, hasLength(2));
      expect(loaded.currentQuestion.prompt, 'Primera pregunta');
      expect(loaded.correctAttemptCount, 0);
      expect(loaded.incorrectAttemptCount, 0);

      final answeredFuture = _waitForPracticeState(
        bloc,
        (state) =>
            state is PracticeLoaded &&
            state.answered &&
            state.progressSnapshot.answeredQuestionCount == 1,
      );
      bloc.add(const AnswerPressed(QuestionOption.b));
      final answered = await answeredFuture as PracticeLoaded;

      expect(answered.selectedOption, QuestionOption.b);
      expect(answered.correctAttemptCount, 1);
      expect(answered.incorrectAttemptCount, 0);
      expect(progressStore.recordedAnswers, hasLength(1));
      expect(progressStore.recordedAnswers.single.questionCode, '1A01001');
    });

    test('shuffles answer presentation for loaded questions', () async {
      final progressStore = FakeQuestionProgressStore();
      final question = buildQuestions().first;
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => [question],
        questionProgressStore: progressStore,
        answerShuffleRandom: Random(1),
      );
      addTearDown(bloc.close);

      final loadedFuture = _waitForPracticeState(
        bloc,
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      final loaded = await loadedFuture as PracticeLoaded;
      final loadedQuestion = loaded.currentQuestion;
      final answerPresentation = loaded.currentAnswerPresentation;

      expect(identical(loadedQuestion, question), isTrue);
      expect(loadedQuestion.correctOption, QuestionOption.b);
      expect(
        loadedQuestion.answers.map((answer) => answer.option),
        QuestionOption.values,
      );
      expect(
        answerPresentation.answers.map((answer) => answer.option),
        isNot([
          QuestionOption.a,
          QuestionOption.b,
          QuestionOption.c,
          QuestionOption.d,
        ]),
      );
      expect(
        answerPresentation.answers.indexWhere(
          (answer) => answer.option == QuestionOption.b,
        ),
        isNot(1),
      );
    });

    test('keeps original answer order when shuffling is disabled', () async {
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => [buildQuestions().first],
        questionProgressStore: progressStore,
        answerShuffleRandom: Random(1),
        session: const PracticeSessionConfig.standard(shuffleAnswers: false),
      );
      addTearDown(bloc.close);

      final loadedFuture = _waitForPracticeState(
        bloc,
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      final loaded = await loadedFuture as PracticeLoaded;

      expect(
        loaded.currentAnswerPresentation.answers.map((answer) => answer.option),
        QuestionOption.values,
      );
    });

    test(
      'keeps original answer order for a non-shuffleable question',
      () async {
        final progressStore = FakeQuestionProgressStore();
        addTearDown(progressStore.close);
        final nonShuffleableQuestion = Question(
          code: '1A01003',
          section: '1A',
          prompt: 'Tercera pregunta',
          answers: const [
            QuestionAnswer(option: QuestionOption.a, text: 'Respuesta A'),
            QuestionAnswer(option: QuestionOption.b, text: 'Respuesta B'),
            QuestionAnswer(option: QuestionOption.c, text: 'Respuesta C'),
            QuestionAnswer(
              option: QuestionOption.d,
              text: 'Las respuestas A y B son correctas',
            ),
          ],
          correctOption: QuestionOption.d,
          norma: 'Norma tercera',
          shuffleable: false,
        );
        final bloc = PracticeBloc(
          loadQuestions: (_) async => [nonShuffleableQuestion],
          questionProgressStore: progressStore,
          answerShuffleRandom: Random(1),
        );
        addTearDown(bloc.close);

        final loadedFuture = _waitForPracticeState(
          bloc,
          (state) => state is PracticeLoaded,
        );
        bloc.add(const PracticeStarted());
        final loaded = await loadedFuture as PracticeLoaded;

        expect(
          loaded.currentAnswerPresentation.answers.map(
            (answer) => answer.option,
          ),
          QuestionOption.values,
        );
      },
    );

    test('advances after answering', () async {
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => buildQuestions(),
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = _waitForPracticeState(
        bloc,
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      await loadedFuture;

      final answeredFuture = _waitForPracticeState(
        bloc,
        (state) =>
            state is PracticeLoaded &&
            state.answered &&
            state.progressSnapshot.answeredQuestionCount == 1,
      );
      bloc.add(const AnswerPressed(QuestionOption.b));
      await answeredFuture;

      final advancedFuture = _waitForPracticeState(
        bloc,
        (state) =>
            state is PracticeLoaded &&
            state.currentIndex == 1 &&
            !state.answered,
      );
      bloc.add(const NextQuestionPressed());
      final advanced = await advancedFuture as PracticeLoaded;

      expect(advanced.currentQuestion.prompt, 'Segunda pregunta');
      expect(advanced.correctAttemptCount, 1);
      expect(advanced.incorrectAttemptCount, 0);
    });

    test('does not advance while an answer is being recorded', () async {
      final progressStore = _SlowQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => buildQuestions(),
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = _waitForPracticeState(
        bloc,
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      await loadedFuture;

      final recordingFuture = _waitForPracticeState(
        bloc,
        (state) => state is PracticeLoaded && state.isRecordingAnswer,
      );
      bloc.add(const AnswerPressed(QuestionOption.b));
      final recording = await recordingFuture as PracticeLoaded;

      expect(recording.answered, isTrue);
      expect(recording.currentIndex, 0);

      bloc.add(const NextQuestionPressed());
      await Future<void>.delayed(Duration.zero);

      expect((bloc.state as PracticeLoaded).currentIndex, 0);

      progressStore.completePendingRecords();

      final recordedFuture = _waitForPracticeState(
        bloc,
        (state) =>
            state is PracticeLoaded &&
            state.answered &&
            !state.isRecordingAnswer,
      );
      await recordedFuture;

      final advancedFuture = _waitForPracticeState(
        bloc,
        (state) => state is PracticeLoaded && state.currentIndex == 1,
      );
      bloc.add(const NextQuestionPressed());
      final advanced = await advancedFuture as PracticeLoaded;

      expect(advanced.currentQuestion.prompt, 'Segunda pregunta');
    });

    test('skips ahead without answering', () async {
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => buildQuestions(),
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = _waitForPracticeState(
        bloc,
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      await loadedFuture;

      final skippedFuture = _waitForPracticeState(
        bloc,
        (state) =>
            state is PracticeLoaded &&
            state.currentIndex == 1 &&
            !state.answered,
      );
      bloc.add(const NextQuestionPressed());
      final skipped = await skippedFuture as PracticeLoaded;

      expect(skipped.currentQuestion.prompt, 'Segunda pregunta');
      expect(skipped.correctAttemptCount, 0);
      expect(skipped.incorrectAttemptCount, 0);
      expect(progressStore.recordedAnswers, isEmpty);
    });

    test('goes back to a skipped question and can still answer it', () async {
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => buildQuestions(),
        questionProgressStore: progressStore,
      );
      addTearDown(bloc.close);

      final loadedFuture = _waitForPracticeState(
        bloc,
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      await loadedFuture;

      final skippedFuture = _waitForPracticeState(
        bloc,
        (state) => state is PracticeLoaded && state.currentIndex == 1,
      );
      bloc.add(const NextQuestionPressed());
      await skippedFuture;

      final backFuture = _waitForPracticeState(
        bloc,
        (state) =>
            state is PracticeLoaded &&
            state.currentIndex == 0 &&
            !state.answered,
      );
      bloc.add(const PreviousQuestionPressed());
      await backFuture;

      final answeredFuture = _waitForPracticeState(
        bloc,
        (state) =>
            state is PracticeLoaded &&
            state.answered &&
            !state.isRecordingAnswer,
      );
      bloc.add(const AnswerPressed(QuestionOption.b));
      final answered = await answeredFuture as PracticeLoaded;

      expect(answered.currentQuestion.prompt, 'Primera pregunta');
      expect(answered.selectedOption, QuestionOption.b);
    });

    test(
      'remembers each question\'s own answer when navigating back',
      () async {
        final progressStore = FakeQuestionProgressStore();
        addTearDown(progressStore.close);
        final bloc = PracticeBloc(
          loadQuestions: (_) async => buildQuestions(),
          questionProgressStore: progressStore,
        );
        addTearDown(bloc.close);

        final loadedFuture = _waitForPracticeState(
          bloc,
          (state) => state is PracticeLoaded,
        );
        bloc.add(const PracticeStarted());
        await loadedFuture;

        final firstAnsweredFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              state.answered &&
              !state.isRecordingAnswer,
        );
        bloc.add(const AnswerPressed(QuestionOption.b));
        await firstAnsweredFuture;

        final advancedFuture = _waitForPracticeState(
          bloc,
          (state) => state is PracticeLoaded && state.currentIndex == 1,
        );
        bloc.add(const NextQuestionPressed());
        await advancedFuture;

        expect((bloc.state as PracticeLoaded).answered, isFalse);

        final backFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              state.currentIndex == 0 &&
              state.answered,
        );
        bloc.add(const PreviousQuestionPressed());
        final back = await backFuture as PracticeLoaded;

        expect(back.selectedOption, QuestionOption.b);
      },
    );

    blocTest<PracticeBloc, PracticeState>(
      'does not go back past the first question',
      setUp: () {
        noOpProgressStore = FakeQuestionProgressStore();
      },
      build: () => PracticeBloc(
        loadQuestions: (_) async => buildQuestions(),
        questionProgressStore: noOpProgressStore,
      ),
      seed: _unansweredPracticeState,
      act: (bloc) => bloc.add(const PreviousQuestionPressed()),
      expect: () => <PracticeState>[],
      tearDown: () => noOpProgressStore.close(),
    );

    test('jumps directly to a selected question', () async {
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => buildQuestions(),
        questionProgressStore: progressStore,
        session: const PracticeSessionConfig.simulacro(),
      );
      addTearDown(bloc.close);

      final loadedFuture = _waitForPracticeState(
        bloc,
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      final loaded = await loadedFuture as PracticeLoaded;

      expect(loaded.isQuestionDrawerNavigationEnabled, isTrue);

      final jumpedFuture = _waitForPracticeState(
        bloc,
        (state) => state is PracticeLoaded && state.currentIndex == 1,
      );
      bloc.add(const QuestionNavigationPressed(1));
      final jumped = await jumpedFuture as PracticeLoaded;

      expect(jumped.currentQuestion.prompt, 'Segunda pregunta');
    });

    blocTest<PracticeBloc, PracticeState>(
      'ignores question navigation with an invalid index',
      setUp: () {
        noOpProgressStore = FakeQuestionProgressStore();
      },
      build: () => PracticeBloc(
        loadQuestions: (_) async => buildQuestions(),
        questionProgressStore: noOpProgressStore,
      ),
      seed: _unansweredPracticeState,
      act: (bloc) => bloc.add(const QuestionNavigationPressed(12)),
      expect: () => <PracticeState>[],
      tearDown: () => noOpProgressStore.close(),
    );

    test(
      'ignores question navigation while an answer is being recorded',
      () async {
        final progressStore = _SlowQuestionProgressStore();
        addTearDown(progressStore.close);
        final bloc = PracticeBloc(
          loadQuestions: (_) async => buildQuestions(),
          questionProgressStore: progressStore,
        );
        addTearDown(bloc.close);

        final loadedFuture = _waitForPracticeState(
          bloc,
          (state) => state is PracticeLoaded,
        );
        bloc.add(const PracticeStarted());
        await loadedFuture;

        final recordingFuture = _waitForPracticeState(
          bloc,
          (state) => state is PracticeLoaded && state.isRecordingAnswer,
        );
        bloc.add(const AnswerPressed(QuestionOption.b));
        await recordingFuture;

        bloc.add(const QuestionNavigationPressed(1));
        await Future<void>.delayed(Duration.zero);

        expect((bloc.state as PracticeLoaded).currentIndex, 0);

        final recordedFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              state.answered &&
              !state.isRecordingAnswer,
        );
        progressStore.completePendingRecords();
        await recordedFuture;
      },
    );

    blocTest<PracticeBloc, PracticeState>(
      'requires the last question to be answered before advancing further',
      setUp: () {
        noOpProgressStore = FakeQuestionProgressStore();
      },
      build: () => PracticeBloc(
        loadQuestions: (_) async => buildQuestions(),
        questionProgressStore: noOpProgressStore,
        session: const PracticeSessionConfig.simulacro(),
      ),
      seed: () => _unansweredPracticeState(
        currentIndex: 1,
        session: const PracticeSessionConfig.simulacro(),
      ),
      act: (bloc) => bloc.add(const NextQuestionPressed()),
      expect: () => <PracticeState>[],
      tearDown: () => noOpProgressStore.close(),
    );

    test(
      'review mode loops remaining questions until all are correct',
      () async {
        final progressStore = FakeQuestionProgressStore();
        addTearDown(progressStore.close);
        await progressStore.recordAnswer(
          QuestionAnswerRecord(
            questionCode: '1A01001',
            section: '1A',
            selectedOption: QuestionOption.a,
            correctOption: QuestionOption.b,
          ),
        );
        await progressStore.recordAnswer(
          QuestionAnswerRecord(
            questionCode: '1A01002',
            section: '1A',
            selectedOption: QuestionOption.b,
            correctOption: QuestionOption.a,
          ),
        );
        final bloc = PracticeBloc(
          loadQuestions: (_) async => buildQuestions(),
          questionProgressStore: progressStore,
          session: const PracticeSessionConfig.review(),
        );
        addTearDown(bloc.close);

        final loadedFuture = _waitForPracticeState(
          bloc,
          (state) => state is PracticeLoaded,
        );
        bloc.add(const PracticeStarted());
        final loaded = await loadedFuture as PracticeLoaded;

        expect(loaded.questions, hasLength(2));
        expect(loaded.mode, PracticeMode.review);

        final firstAnsweredFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              state.answered &&
              !state.isRecordingAnswer &&
              state.incorrectAttemptCount == 1,
        );
        bloc.add(const AnswerPressed(QuestionOption.a));
        await firstAnsweredFuture;

        final advancedFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              state.currentQuestion.prompt == 'Segunda pregunta' &&
              !state.answered,
        );
        bloc.add(const NextQuestionPressed());
        await advancedFuture;

        final secondAnsweredFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              state.answered &&
              !state.isRecordingAnswer &&
              state.correctAttemptCount == 1,
        );
        bloc.add(const AnswerPressed(QuestionOption.a));
        await secondAnsweredFuture;

        final loopedFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              state.remainingFilteredQuestions.length == 1 &&
              state.currentQuestion.prompt == 'Primera pregunta' &&
              !state.answered,
        );
        bloc.add(const NextQuestionPressed());
        final looped = await loopedFuture as PracticeLoaded;

        expect(looped.questions, hasLength(2));

        final completedFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              state.answered &&
              !state.isRecordingAnswer &&
              state.isFilteredPracticeComplete,
        );
        bloc.add(const AnswerPressed(QuestionOption.b));
        final completed = await completedFuture as PracticeLoaded;

        expect(completed.correctAttemptCount, 2);
        expect(completed.incorrectAttemptCount, 1);
      },
    );

    test(
      'review mode allows repeated attempts at one incorrect question',
      () async {
        final progressStore = FakeQuestionProgressStore();
        addTearDown(progressStore.close);
        await progressStore.recordAnswer(
          QuestionAnswerRecord(
            questionCode: '1A01001',
            section: '1A',
            selectedOption: QuestionOption.a,
            correctOption: QuestionOption.b,
          ),
        );
        final bloc = PracticeBloc(
          loadQuestions: (_) async => [buildQuestions().first],
          questionProgressStore: progressStore,
          session: const PracticeSessionConfig.review(),
        );
        addTearDown(bloc.close);

        final loadedFuture = _waitForPracticeState(
          bloc,
          (state) => state is PracticeLoaded,
        );
        bloc.add(const PracticeStarted());
        await loadedFuture;

        for (var attempt = 1; attempt <= 2; attempt += 1) {
          final answeredFuture = _waitForPracticeState(
            bloc,
            (state) =>
                state is PracticeLoaded &&
                state.incorrectAttemptCount == attempt &&
                state.answered &&
                !state.isRecordingAnswer,
          );
          bloc.add(const AnswerPressed(QuestionOption.a));
          await answeredFuture;

          final reopenedFuture = _waitForPracticeState(
            bloc,
            (state) =>
                state is PracticeLoaded &&
                state.incorrectAttemptCount == attempt &&
                !state.answered,
          );
          bloc.add(const NextQuestionPressed());
          await reopenedFuture;
        }

        final completedFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              state.correctAttemptCount == 1 &&
              state.incorrectAttemptCount == 2 &&
              state.answered &&
              !state.isRecordingAnswer &&
              state.isFilteredPracticeComplete,
        );
        bloc.add(const AnswerPressed(QuestionOption.b));
        await completedFuture;

        expect(progressStore.recordedAnswers, hasLength(4));
        expect(
          progressStore.recordedAnswers.map((answer) => answer.selectedOption),
          [
            QuestionOption.a,
            QuestionOption.a,
            QuestionOption.a,
            QuestionOption.b,
          ],
        );
      },
    );

    test(
      'pending mode loops remaining unanswered questions until all are answered',
      () async {
        final progressStore = FakeQuestionProgressStore();
        addTearDown(progressStore.close);
        final bloc = PracticeBloc(
          loadQuestions: (_) async => buildQuestions(),
          questionProgressStore: progressStore,
          session: PracticeSessionConfig.pending(),
        );
        addTearDown(bloc.close);

        final loadedFuture = _waitForPracticeState(
          bloc,
          (state) => state is PracticeLoaded,
        );
        bloc.add(const PracticeStarted());
        final loaded = await loadedFuture as PracticeLoaded;

        expect(loaded.questions, hasLength(2));
        expect(loaded.mode, PracticeMode.pending);

        final firstAnsweredFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              state.answered &&
              !state.isRecordingAnswer &&
              state.incorrectAttemptCount == 1,
        );
        bloc.add(const AnswerPressed(QuestionOption.a));
        await firstAnsweredFuture;

        final advancedFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              state.remainingFilteredQuestions.length == 1 &&
              state.currentQuestion.prompt == 'Segunda pregunta' &&
              !state.answered,
        );
        bloc.add(const NextQuestionPressed());
        await advancedFuture;

        final completedFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              state.answered &&
              !state.isRecordingAnswer &&
              state.isFilteredPracticeComplete,
        );
        bloc.add(const AnswerPressed(QuestionOption.a));
        final completed = await completedFuture as PracticeLoaded;

        expect(completed.correctAttemptCount, 1);
        expect(completed.incorrectAttemptCount, 1);
      },
    );

    test('pending mode loads more questions when five remain', () async {
      final progressStore = FakeQuestionProgressStore();
      final questions = buildManyQuestions(15);
      final loadMoreCalls = <Set<String>>[];
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => questions.take(10).toList(growable: false),
        loadMoreQuestions: (_, loadedQuestionCodes, progressSnapshot) async {
          loadMoreCalls.add({...loadedQuestionCodes});
          final batch = questions
              .where(
                (question) =>
                    !loadedQuestionCodes.contains(question.code) &&
                    progressSnapshot.progressFor(question.code) == null,
              )
              .take(10)
              .toList(growable: false);
          return PendingQuestionBatch(questions: batch, hasMore: false);
        },
        questionProgressStore: progressStore,
        session: PracticeSessionConfig.pending(),
      );
      addTearDown(bloc.close);

      final loadedFuture = _waitForPracticeState(
        bloc,
        (state) => state is PracticeLoaded,
      );
      bloc.add(const PracticeStarted());
      final loaded = await loadedFuture as PracticeLoaded;

      expect(loaded.questions, hasLength(10));

      for (var answeredCount = 1; answeredCount < 5; answeredCount += 1) {
        final answeredFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              state.answered &&
              !state.isRecordingAnswer &&
              state.progressSnapshot.answeredQuestionCount == answeredCount,
        );
        bloc.add(const AnswerPressed(QuestionOption.a));
        await answeredFuture;

        final advancedFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              !state.answered &&
              state.currentQuestion.prompt == 'Pregunta ${answeredCount + 1}',
        );
        bloc.add(const NextQuestionPressed());
        await advancedFuture;
      }

      expect(loadMoreCalls, isEmpty);

      final refilledFuture = _waitForPracticeState(
        bloc,
        (state) =>
            state is PracticeLoaded &&
            state.questions.length == 15 &&
            state.progressSnapshot.answeredQuestionCount == 5,
      );
      bloc.add(const AnswerPressed(QuestionOption.a));
      final refilled = await refilledFuture as PracticeLoaded;

      expect(loadMoreCalls, hasLength(1));
      expect(loadMoreCalls.single, contains('1A00010'));
      // The full, stable set of already-loaded codes is passed (including
      // answered ones) so the caller never re-fetches a duplicate.
      expect(loadMoreCalls.single, contains('1A00001'));
      expect(refilled.remainingFilteredQuestions, hasLength(10));
      expect(
        refilled.remainingFilteredQuestions.map((question) => question.prompt),
        contains('Pregunta 15'),
      );
      expect(refilled.pendingBatchState, isA<PendingBatchExhausted>());
    });

    test('uses hasMore for an exact-size final pending batch', () async {
      final progressStore = FakeQuestionProgressStore();
      final questions = buildManyQuestions(11);
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => [questions.first],
        loadMoreQuestions: (_, _, _) async =>
            PendingQuestionBatch(questions: questions.skip(1), hasMore: false),
        questionProgressStore: progressStore,
        session: PracticeSessionConfig.pending(
          pendingBatchSize: 10,
          shuffleAnswers: false,
        ),
      );
      addTearDown(bloc.close);

      final exhaustedFuture = _waitForPracticeState(
        bloc,
        (state) =>
            state is PracticeLoaded &&
            state.questions.length == 11 &&
            state.pendingBatchState is PendingBatchExhausted,
      );
      bloc.add(const PracticeStarted());
      final exhausted = await exhaustedFuture as PracticeLoaded;

      expect(exhausted.questions, hasLength(11));
      expect(exhausted.pendingBatchState, isA<PendingBatchExhausted>());
    });

    test('confirms exhaustion from an empty pending batch', () async {
      final progressStore = FakeQuestionProgressStore();
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => [],
        loadMoreQuestions: (_, _, _) async =>
            PendingQuestionBatch(questions: const [], hasMore: false),
        questionProgressStore: progressStore,
        session: PracticeSessionConfig.pending(shuffleAnswers: false),
      );
      addTearDown(bloc.close);

      final exhaustedFuture = _waitForPracticeState(
        bloc,
        (state) =>
            state is PracticeLoaded &&
            state.questions.isEmpty &&
            state.pendingBatchState is PendingBatchExhausted,
      );
      bloc.add(const PracticeStarted());
      final exhausted = await exhaustedFuture as PracticeLoaded;

      expect(exhausted.isFilteredPracticeComplete, isTrue);
    });

    test('filters duplicate questions from a pending batch', () async {
      final progressStore = FakeQuestionProgressStore();
      final questions = buildManyQuestions(2);
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) async => [questions.first],
        loadMoreQuestions: (_, _, _) async =>
            PendingQuestionBatch(questions: questions, hasMore: false),
        questionProgressStore: progressStore,
        session: PracticeSessionConfig.pending(shuffleAnswers: false),
      );
      addTearDown(bloc.close);

      final exhaustedFuture = _waitForPracticeState(
        bloc,
        (state) =>
            state is PracticeLoaded &&
            state.questions.length == 2 &&
            state.pendingBatchState is PendingBatchExhausted,
      );
      bloc.add(const PracticeStarted());
      final exhausted = await exhaustedFuture as PracticeLoaded;

      expect(
        exhausted.questions.map((question) => question.code).toSet(),
        hasLength(2),
      );
    });

    test(
      'retries a failed pending batch without restarting the session',
      () async {
        final progressStore = FakeQuestionProgressStore();
        var loadMoreCallCount = 0;
        addTearDown(progressStore.close);
        final bloc = PracticeBloc(
          loadQuestions: (_) async => [],
          loadMoreQuestions: (_, _, _) async {
            loadMoreCallCount += 1;
            if (loadMoreCallCount == 1) {
              throw StateError('Temporary batch failure.');
            }
            return PendingQuestionBatch(
              questions: [buildManyQuestions(1).single],
              hasMore: false,
            );
          },
          questionProgressStore: progressStore,
          session: PracticeSessionConfig.pending(shuffleAnswers: false),
        );
        addTearDown(bloc.close);

        final failedFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              state.pendingBatchState is PendingBatchFailure,
        );
        bloc.add(const PracticeStarted());
        final failed = await failedFuture as PracticeLoaded;

        expect(failed.questions, isEmpty);
        expect(failed.isFilteredPracticeComplete, isFalse);

        final retriedFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              state.questions.length == 1 &&
              state.pendingBatchState is PendingBatchExhausted,
        );
        bloc.add(const PendingBatchRetried());
        final retried = await retriedFuture as PracticeLoaded;

        expect(loadMoreCallCount, 2);
        expect(retried.questions.single.code, '1A00001');
      },
    );

    test(
      'ignores a pending batch from a previously selected section',
      () async {
        final progressStore = FakeQuestionProgressStore();
        final pendingBatches = <String, Completer<PendingQuestionBatch>>{};
        addTearDown(progressStore.close);
        final bloc = PracticeBloc(
          loadQuestions: (section) async => [
            buildReviewQuestions().firstWhere(
              (question) => question.section == section,
            ),
          ],
          loadMoreQuestions: (section, _, _) {
            final completer = Completer<PendingQuestionBatch>();
            pendingBatches[section!] = completer;
            return completer.future;
          },
          questionProgressStore: progressStore,
          session: PracticeSessionConfig.pending(
            initialSection: '1A',
            shuffleAnswers: false,
          ),
        );
        addTearDown(bloc.close);

        bloc.add(const PracticeStarted());
        await _waitUntil(() => pendingBatches.containsKey('1A'));
        bloc.add(const SectionSelected('1B'));
        await _waitUntil(() => pendingBatches.containsKey('1B'));

        final sectionBFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              state.selectedSection == '1B' &&
              state.pendingBatchState is PendingBatchExhausted,
        );
        pendingBatches['1B']!.complete(
          PendingQuestionBatch(questions: const [], hasMore: false),
        );
        await sectionBFuture;

        pendingBatches['1A']!.complete(
          PendingQuestionBatch(
            questions: [buildManyQuestions(1).single],
            hasMore: false,
          ),
        );
        await Future<void>.delayed(Duration.zero);

        final currentState = bloc.state as PracticeLoaded;
        expect(currentState.selectedSection, '1B');
        expect(currentState.questions.single.section, '1B');
      },
    );

    test('keeps the latest section when loads finish out of order', () async {
      final progressStore = FakeQuestionProgressStore();
      final pendingLoads = <String, Completer<List<Question>>>{};
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (section) {
          final completer = Completer<List<Question>>();
          pendingLoads[section!] = completer;
          return completer.future;
        },
        questionProgressStore: progressStore,
        session: const PracticeSessionConfig.standard(initialSection: null),
      );
      addTearDown(bloc.close);

      bloc.add(const SectionSelected('1A'));
      await _waitUntil(() => pendingLoads.containsKey('1A'));
      bloc.add(const SectionSelected('1B'));
      await _waitUntil(() => pendingLoads.containsKey('1B'));

      final latestLoadedFuture = _waitForPracticeState(
        bloc,
        (state) => state is PracticeLoaded && state.selectedSection == '1B',
      );
      pendingLoads['1B']!.complete([buildReviewQuestions().last]);
      final latestLoaded = await latestLoadedFuture as PracticeLoaded;

      pendingLoads['1A']!.complete([buildReviewQuestions().first]);
      await Future<void>.delayed(Duration.zero);

      expect(latestLoaded.currentQuestion.section, '1B');
      expect((bloc.state as PracticeLoaded).selectedSection, '1B');
      expect((bloc.state as PracticeLoaded).currentQuestion.section, '1B');
    });

    test(
      'does not restore an old section after its answer save finishes',
      () async {
        final progressStore = _SlowQuestionProgressStore();
        addTearDown(progressStore.close);
        final bloc = PracticeBloc(
          loadQuestions: loadReviewQuestions,
          questionProgressStore: progressStore,
          session: const PracticeSessionConfig.standard(shuffleAnswers: false),
        );
        addTearDown(bloc.close);

        final initialLoadedFuture = _waitForPracticeState(
          bloc,
          (state) => state is PracticeLoaded,
        );
        bloc.add(const PracticeStarted());
        await initialLoadedFuture;

        final recordingFuture = _waitForPracticeState(
          bloc,
          (state) => state is PracticeLoaded && state.isRecordingAnswer,
        );
        bloc.add(const AnswerPressed(QuestionOption.b));
        await recordingFuture;

        // Duplicate input while the write is active is intentionally ignored.
        bloc.add(const AnswerPressed(QuestionOption.a));

        final nextSectionFuture = _waitForPracticeState(
          bloc,
          (state) => state is PracticeLoaded && state.selectedSection == '1B',
        );
        bloc.add(const SectionSelected('1B'));
        await nextSectionFuture;

        progressStore.completePendingRecords();
        await _waitUntil(() => progressStore.recordedAnswers.length == 1);
        await Future<void>.delayed(Duration.zero);

        final currentState = bloc.state as PracticeLoaded;
        expect(currentState.selectedSection, '1B');
        expect(currentState.currentQuestion.section, '1B');
        expect(currentState.selectedOptionsByQuestionCode, isEmpty);
        expect(progressStore.recordedAnswers, hasLength(1));
        expect(progressStore.recordedAnswers.single.questionCode, '1A01001');
      },
    );

    test(
      'preserves navigation and answers when a pending refill finishes',
      () async {
        final progressStore = FakeQuestionProgressStore();
        final refill = Completer<PendingQuestionBatch>();
        final refillStarted = Completer<void>();
        addTearDown(progressStore.close);
        final bloc = PracticeBloc(
          loadQuestions: (_) async => buildManyQuestions(6),
          loadMoreQuestions: (_, _, _) {
            refillStarted.complete();
            return refill.future;
          },
          questionProgressStore: progressStore,
          session: PracticeSessionConfig.pending(shuffleAnswers: false),
        );
        addTearDown(bloc.close);

        final loadedFuture = _waitForPracticeState(
          bloc,
          (state) => state is PracticeLoaded,
        );
        bloc.add(const PracticeStarted());
        await loadedFuture;

        final recordedFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              state.answered &&
              !state.isRecordingAnswer,
        );
        bloc.add(const AnswerPressed(QuestionOption.a));
        await recordedFuture;
        await refillStarted.future;

        final navigatedFuture = _waitForPracticeState(
          bloc,
          (state) => state is PracticeLoaded && state.currentIndex == 1,
        );
        bloc.add(const NextQuestionPressed());
        await navigatedFuture;

        final secondRecordedFuture = _waitForPracticeState(
          bloc,
          (state) =>
              state is PracticeLoaded &&
              state.currentIndex == 1 &&
              state.answered &&
              !state.isRecordingAnswer,
        );
        bloc.add(const AnswerPressed(QuestionOption.a));
        await secondRecordedFuture;

        final refilledFuture = _waitForPracticeState(
          bloc,
          (state) => state is PracticeLoaded && state.questions.length == 8,
        );
        refill.complete(
          PendingQuestionBatch(
            questions: buildManyQuestions(8).skip(6),
            hasMore: false,
          ),
        );
        final refilled = await refilledFuture as PracticeLoaded;

        expect(refilled.currentIndex, 1);
        expect(refilled.currentQuestion.code, '1A00002');
        expect(refilled.selectedOptionsByQuestionCode, {
          '1A00001': QuestionOption.a,
          '1A00002': QuestionOption.a,
        });
      },
    );

    test('ignores a load result that completes while closing', () async {
      final progressStore = FakeQuestionProgressStore();
      final loadCompleter = Completer<List<Question>>();
      var loadStarted = false;
      addTearDown(progressStore.close);
      final bloc = PracticeBloc(
        loadQuestions: (_) {
          loadStarted = true;
          return loadCompleter.future;
        },
        questionProgressStore: progressStore,
      );

      bloc.add(const PracticeStarted());
      await _waitUntil(() => loadStarted);

      final closeFuture = bloc.close();
      loadCompleter.complete(buildQuestions());
      await closeFuture;

      expect(bloc.state, isA<PracticeLoading>());
      expect(progressStore.recordedAnswers, isEmpty);
    });
  });
}

Future<PracticeState> _waitForPracticeState(
  PracticeBloc bloc,
  bool Function(PracticeState state) predicate,
) {
  return bloc.stream
      .firstWhere(predicate)
      .timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TestFailure(
          'Timed out waiting for a PracticeBloc transition; '
          'current state: ${bloc.state.runtimeType}',
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

PracticeLoaded _unansweredPracticeState({
  int currentIndex = 0,
  PracticeSessionConfig session = const PracticeSessionConfig.standard(),
}) {
  return PracticeLoaded(
    selectedSection: '1A',
    session: session,
    questions: buildQuestions(),
    currentIndex: currentIndex,
  );
}

final class _SlowQuestionProgressStore extends FakeQuestionProgressStore {
  final List<Completer<void>> _pendingRecords = [];

  @override
  Future<void> recordAnswer(QuestionAnswerRecord answer) async {
    final completer = Completer<void>();
    _pendingRecords.add(completer);
    await completer.future;
    await super.recordAnswer(answer);
  }

  void completePendingRecords() {
    for (final completer in _pendingRecords) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }
}
